package fixer

import (
	"fmt"
	"github.com/onflow/cadence/runtime/ast"
	"github.com/onflow/cadence/runtime/common"
	"github.com/onflow/cadence/runtime/parser"
	"github.com/onflow/cadence/runtime/sema"
	"github.com/onflow/cadence/runtime/stdlib"
	"os"
	"path"
	"path/filepath"
	"strings"
)

func FixFile(spath string, newFileNameFormatted string, code string) {
	var fixed bool = false
	fmt.Println("Fix File:", spath)
	for {
		parserFixer := NewParseFixer(spath, code)
		fixed, code, _ = parserFixer.ParseAndFix()
		if fixed {
			continue
		}
		break
	}

	astFixer := NewAstFixer(spath, code, false)
	for {
		fixed, code = astFixer.WalkAndFix()
		if fixed {
			continue
		}

		//checker
		fixed, code = astFixer.CheckAndFix(spath)
		if fixed {
			continue
		}

		break

	}

	var output = PrettyCode(string(code), 100, true)
	dir := path.Dir(newFileNameFormatted)
	os.MkdirAll(dir, 0777)
	os.Create(newFileNameFormatted)
	os.WriteFile(newFileNameFormatted, []byte(output), 0644)
}

func must(err error, location common.Location, codes map[common.Location][]byte) {
	if err == nil {
		return
	}
}

func mustClosure(location common.Location, codes map[common.Location][]byte) func(error) {
	return func(e error) {
		must(e, location, codes)
	}
}

func PrepareProgramFromFile(location string, codes map[common.Location][]byte) (*ast.Program, func(error)) {
	code, err := os.ReadFile(location)
	program, must := PrepareProgram(code, common.StringLocation(location), codes)
	must(err)

	return program, must
}

func PrepareProgram(code []byte, location common.Location, codes map[common.Location][]byte) (*ast.Program, func(error)) {
	must := mustClosure(location, codes)

	program, err := parser.ParseProgram(nil, code, parser.Config{})
	codes[location] = code
	must(err)

	return program, must
}
func DefaultCheckerConfig(
	checkers map[common.Location]*sema.Checker,
	codes map[common.Location][]byte,
	standardLibraryValues []stdlib.StandardLibraryValue,
) *sema.Config {

	// NOTE: also declare values in the interpreter, e.g. for the `REPL` in `NewREPL`
	baseValueActivation := sema.NewVariableActivation(sema.BaseValueActivation)

	for _, valueDeclaration := range standardLibraryValues {
		baseValueActivation.DeclareValue(valueDeclaration)
	}

	return &sema.Config{
		BaseValueActivationHandler: func(_ common.Location) *sema.VariableActivation {
			return baseValueActivation
		},
		AccessCheckMode: sema.AccessCheckModeNone,
		ImportHandler: func(
			checker *sema.Checker,
			importedLocation common.Location,
			r ast.Range,
		) (sema.Import, error) {

			if importedLocation == stdlib.CryptoCheckerLocation {
				cryptoChecker := stdlib.CryptoChecker()
				return sema.ElaborationImport{
					Elaboration: cryptoChecker.Elaboration,
				}, nil
			}

			stringLocation, ok := importedLocation.(common.StringLocation)
			if ok {

				oldPath := path.Join(path.Dir(checker.Location.String()), stringLocation.String())

				name := path.Base(oldPath)
				libPath := fmt.Sprintf("./standardsV1/%s", name)
				_, err := os.ReadFile(libPath)
				if err == nil {
					oldPath = libPath
				}

				newPath := strings.Replace(oldPath, "contracts/", "contractsV1/", 1)
				_, err = os.ReadFile(newPath)

				if err != nil {
					code, _ := os.ReadFile(oldPath)
					FixFile(oldPath, newPath, string(code))
				}

				importedProgram, _ := PrepareProgramFromFile(newPath, codes)
				importedChecker, _ := checker.SubChecker(importedProgram, common.StringLocation(newPath))
				importedChecker.Check()

				return sema.ElaborationImport{
					Elaboration: importedChecker.Elaboration,
				}, nil
			}

			return nil, &sema.CheckerError{
				Location: checker.Location,
				Codes:    codes,
				Errors: []error{
					fmt.Errorf("cannot import `%s`. only files are supported", importedLocation),
				},
			}

		},
		AttachmentsEnabled: true,
	}
}

func PrepareChecker(
	program *ast.Program,
	location common.Location,
	checkers map[common.Location]*sema.Checker,
	codes map[common.Location][]byte,
	memberAccountAccess map[common.Location]map[common.Location]struct{},
	standardLibraryValues []stdlib.StandardLibraryValue,
	must func(error),
) (*sema.Checker, func(error)) {

	config := DefaultCheckerConfig(checkers, codes, standardLibraryValues)

	config.MemberAccountAccessHandler = func(checker *sema.Checker, memberLocation common.Location) bool {
		if memberAccountAccess == nil {
			return false
		}

		targets, ok := memberAccountAccess[checker.Location]
		if !ok {
			return false
		}

		_, ok = targets[memberLocation]
		return ok
	}

	checker, err := sema.NewChecker(
		program,
		location,
		nil,
		config,
	)
	must(err)

	return checker, must
}

type AstFixer struct {
	appliedFix bool
	program    *ast.Program
	checkers   map[common.Location]*sema.Checker
	codes      map[common.Location][]byte

	code             string
	path             string
	replaceFunctions bool

	capabilityIndex int

	needsPurity map[string]bool
	needsAccess map[string]sema.Access
}

func NewAstFixer(path string, code string, replaceFunctions bool) *AstFixer {

	program, err := parser.ParseProgram(nil, []byte(code), parser.Config{})
	if err != nil {
		fmt.Println(path)
		panic(err)
	}

	return &AstFixer{
		appliedFix:       false,
		program:          program,
		codes:            make(map[common.Location][]byte),
		checkers:         make(map[common.Location]*sema.Checker),
		code:             code,
		path:             path,
		replaceFunctions: replaceFunctions,
		capabilityIndex:  0,

		needsPurity: make(map[string]bool),
		needsAccess: make(map[string]sema.Access),
	}
}

func (fixer *AstFixer) updateProgram() {
	program, err := parser.ParseProgram(nil, []byte(fixer.code), parser.Config{})
	if err != nil {
		panic(err)
	}
	fixer.program = program
	fixer.appliedFix = false
}

func (fixer *AstFixer) WalkAndFix() (bool, string) {
	fixer.updateProgram()
	fixer.program.Walk(fixer.walker)
	return fixer.appliedFix, fixer.code
}

func (fixer *AstFixer) CheckAndFix(path string) (bool, string) {
	fixer.updateProgram()
	var checker *sema.Checker
	var must func(error)

	fixer.codes = make(map[common.Location][]byte)
	fixer.checkers = make(map[common.Location]*sema.Checker)

	memberAccountAccess := make(map[common.Location]map[common.Location]struct{})
	location := common.NewStringLocation(nil, path)
	standardLibraryValues := stdlib.DefaultStandardLibraryValues(nil)

	program, must := PrepareProgram([]byte(fixer.code), location, fixer.codes)
	checker, _ = PrepareChecker(
		program,
		location,
		fixer.checkers,
		fixer.codes,
		memberAccountAccess,
		standardLibraryValues,
		must,
	)

	err := checker.Check()

	checkerError, ok := err.(*sema.CheckerError)
	if !ok {
		//all done
		return false, fixer.code
	}

	for _, e := range checkerError.Errors {
		fmt.Println("V:", e)
		switch v := e.(type) {
		case *sema.InvalidUnaryOperandError:
			//ignore
			continue
		case *sema.NotDeclaredMemberError:

			if strings.HasSuffix(v.Type.String(), "&Account") {
				fmt.Println("Fixing &Account")

				switch v.Expression.Identifier.String() {
				case "storageUsed":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.used")
				case "storageCapacity":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.capacity")
				case "save":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.save")
				case "borrow":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.borrow")
				case "getCapability":
					elem := FindElement(program, v.StartPosition(), ast.ElementTypeInvocationExpression)
					invocation := elem.(*ast.InvocationExpression)
					fixer.ReplaceElement(
						elem,
						strings.ReplaceAll(invocation.String(), "getCapability", "capabilities.get")+"!",
					)
				case "link":
					endPos := v.EndPos
					endPos.Offset = endPos.Offset + 1
					elem := FindElement(program, endPos, ast.ElementTypeInvocationExpression).(*ast.InvocationExpression)
					if elem.InvokedExpression.String() == "self.account.link" {
						var publicPath = elem.Arguments[0].String()
						var storagePath = elem.Arguments[1].String()
						var linkType = elem.TypeArguments[0].String()
						fixer.capabilityIndex++
						data := fmt.Sprintf("var _capForLinked%d = self.account.capabilities.storage.issue<%s>(%s)\n", fixer.capabilityIndex, linkType, storagePath)
						data = data + fmt.Sprintf("self.account.capabilities.publish(_capForLinked%d , at:%s)\n", fixer.capabilityIndex, publicPath)
						data = data
						fixer.ReplaceElement(elem, data)
					}
				}
			}

		case *sema.NotDeclaredError:
			fmt.Println("Fixing Missing Declarations:", v.Name)

			if v.Name == "ViewResolver" {
				//add import
				fmt.Println("Adding import")

				fixer.code = AddImportToProgram(fixer.code, checker.Location, program, "ViewResolver")
				fixer.appliedFix = true
				break
			}

			if v.Name == "MetadataViews.Resolver" {
				fmt.Println(fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1])
				fixer.ReplaceElement(v, "ViewResolver.Resolver")
				break
			}

			if v.Name == "MetadataViews.ResolverCollection" {
				fmt.Println(fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1])
				fixer.ReplaceElement(v, "ViewResolver.ResolverCollection")
				break
			}

			if v.Name == "PublicAccount" {
				fixer.ReplaceElement(v, "&Account")
				break
			}

			if v.Name == "unsafeRandom" {
				fixer.ReplaceElement(v, "revertibleRandom<UInt64>")
				break
			}
			fixer.appliedFix = false

		case *sema.InvalidInterfaceTypeError:
			fmt.Println("Fixing Interface Type")
			fmt.Println("Actual Type:", v.ActualType.QualifiedString())
			fmt.Println("Expected Type:", v.ExpectedType.QualifiedString())

			prefix := ""
			if fixer.code[v.StartPosition().Offset] == '(' {
				prefix = "("
			}

			if v.ExpectedType.IsResourceType() {
				fixer.ReplaceElement(v, prefix+"@"+v.ExpectedType.QualifiedString())
			} else {
				fixer.ReplaceElement(v, prefix+v.ExpectedType.QualifiedString())
			}

		case *sema.InsufficientArgumentsError:
			fmt.Println("Fixing Arguments")

			elem := FindElement(program, v.StartPosition(), ast.ElementTypeInvocationExpression)
			if elem != nil {
				expression := elem.(*ast.InvocationExpression)
				if strings.HasSuffix(expression.InvokedExpression.String(), "createEmptyCollection") {
					pre := fixer.code[:expression.ArgumentsStartPos.Offset+1]
					post := fixer.code[expression.ArgumentsStartPos.Offset+1:]
					fixer.code = pre + fmt.Sprintf("nftType: Type<@Collection>()") + post
					fixer.appliedFix = true
				}
			}

		case *sema.PurityError:
			fmt.Println("\nFixing Purity")
			elem := FindElement(program, v.StartPosition(), ast.ElementTypeInvocationExpression)
			invocation := elem.(*ast.InvocationExpression)
			if invocation != nil {
				fmt.Println(invocation.String())
				invoked := strings.Split(invocation.InvokedExpression.String(), ".")
				fmt.Println(invoked)

				if len(invoked) > 1 && invoked[1] != "append" {
					if _, ok := fixer.needsPurity[invoked[len(invoked)-1]]; !ok {
						fmt.Println("setting to fix purity", invoked[len(invoked)-1])
						fixer.needsPurity[invoked[len(invoked)-1]] = true
						fixer.appliedFix = true
					}

				}
			}

		case *sema.UnauthorizedReferenceAssignmentError:
			fmt.Println("Fixing Reference Entitlements")
			elem := FindElement(program, v.StartPosition(), ast.ElementTypeAssignmentStatement)
			assignment := elem.(*ast.AssignmentStatement)

			var target = assignment.Target
			switch t := target.(type) {
			case *ast.IndexExpression:
				var indexed = t.TargetExpression.String()
				if _, ok := fixer.needsAccess[indexed]; !ok {
					fixer.needsAccess[indexed] = v.RequiredAccess[0]
					fixer.appliedFix = true
				}
			default:
				fmt.Printf("%T\n", t)
				panic("d")
			}

		case *sema.NestedReferenceError:
			fmt.Println("Fixing Nested Reference")
			elem := FindElement(program, v.StartPosition(), ast.ElementTypeCastingExpression)
			casting := elem.(*ast.CastingExpression)
			fixer.ReplaceElement(v, casting.Expression.String()[1:])

		case *sema.IncorrectArgumentLabelError:
			fmt.Println("Fixing Labels")
			replacement := v.ExpectedArgumentLabel
			if v.ExpectedArgumentLabel != "" {
				replacement = replacement + ":"
			}
			fixer.ReplaceElement(v, replacement)

		case *sema.TypeMismatchWithDescriptionError:
			inner := fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1]
			fmt.Println("TypeMismatchWithDescriptionError", v.ActualType, v.ExpectedTypeDescription, inner)
			panic("d")

		case *sema.TypeMismatchError:
			inner := fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1]
			fmt.Println("TypeMismatchError", v.ActualType.QualifiedString(), v.ExpectedType.QualifiedString(), inner)

			_, isCasting := v.Expression.(*ast.CastingExpression)
			if isCasting {
				fmt.Println("Fixing Casting")
				replacement := strings.ReplaceAll(inner, v.ActualType.QualifiedString(), v.ExpectedType.QualifiedString())
				fmt.Println(inner)
				fmt.Println(replacement)
				fixer.ReplaceElement(v, replacement)
			}

			if v.ActualType.QualifiedString() == v.ExpectedType.QualifiedString()+"?" {
				if !strings.Contains(inner, "??") {
					fmt.Println("force")
					fixer.ReplaceElement(v, inner+"!")
				}
			}

			if v.ActualType.QualifiedString() == "&"+v.ExpectedType.QualifiedString() {
				fmt.Println("Dereferencing")
				fixer.ReplaceElement(v, "*"+inner)
			}

		case *sema.TypeAnnotationRequiredError:
			fmt.Println("TypeAnnotationRequiredError")
			fmt.Println(v.Cause)
			if strings.Contains(v.Cause, "cannot infer type from reference expression") {
				elem := FindElement(program, v.StartPosition(), ast.ElementTypeCastingExpression)
				casting := elem.(*ast.CastingExpression)
				if casting.Operation == ast.OperationForceCast {
					casting.Operation = ast.OperationCast
					fixer.ReplaceElement(casting, casting.String())
				}
			}

		case *sema.ConformanceError:
			fmt.Println("ConformanceError")
			fmt.Println(v)
			if len(v.MissingMembers) > 0 {
				fmt.Println("Fixing Conformances")
				missing := v.MissingMembers[0]
				if missing.DeclarationKind == common.DeclarationKindFunction {
					newCode := strings.ReplaceAll(missing.TypeAnnotation.QualifiedString(), "fun", fmt.Sprintf("fun %s", missing.Identifier.String()))
					newCode = fmt.Sprintf("access(%s) ", missing.Access.String()) + newCode

					if missing.Identifier.String() == "createEmptyCollection" {
						newCode = newCode + "{\n return <-create Collection() \n}"
					} else if missing.Identifier.String() == "getLength" {
						newCode = newCode + "{\n return self.ownedNFTs.length \n}"
					} else if missing.Identifier.String() == "createEmptyVault" {
						newCode = newCode + "{\n return <-create Vault() \n}"
					} else if missing.Identifier.String() == "isAvailableToWithdraw" {
						newCode = newCode + "{\n return self.balance>=amount \n}"
					} else {
						newCode = newCode + "{\n panic(\"implement me\") \n}"
					}

					fixer.code = AddFunctionToComposite(fixer.code, program, newCode, v.StartPosition())
					fixer.appliedFix = true
					break
				}

			}

			if len(v.MemberMismatches) > 0 {

				mismatch := v.MemberMismatches[0]

				compositeContract := strings.Split(mismatch.CompositeMember.ContainerType.QualifiedString(), ".")[0]
				interfaceContract := strings.Split(mismatch.InterfaceMember.ContainerType.QualifiedString(), ".")[0]

				fmt.Println("CompositeMember", mismatch.CompositeMember.ContainerType.QualifiedString())
				fmt.Println("InterfaceMember", mismatch.InterfaceMember.ContainerType.QualifiedString())

				if interfaceContract != compositeContract {
					fmt.Println("different contract")
					oldcode := fixer.code
					fixer.code = ReplaceFunction(fixer.code, program, mismatch.CompositeMember, mismatch.InterfaceMember)
					fixer.appliedFix = fixer.code != oldcode
					break
				} else {
					fmt.Println("same contract")
					//reverse
					oldcode := fixer.code
					fixer.code = ReplaceFunction(fixer.code, program, mismatch.InterfaceMember, mismatch.CompositeMember)
					fixer.appliedFix = fixer.code != oldcode
					break
				}

			}

		default:
			fmt.Println("ERR:", v)
			fmt.Printf("%T\n", v)
			//fixer.appliedFix = false
		}

		if fixer.appliedFix {
			break
		}
	}

	return fixer.appliedFix, fixer.code

}

func (fixer *AstFixer) ReplaceElement(old ast.HasPosition, replacement string) {
	fmt.Println(fixer.code[old.StartPosition().Offset : old.EndPosition(nil).Offset+1])
	fmt.Println("replace:", replacement)
	pre := fixer.code[:old.StartPosition().Offset]
	post := fixer.code[old.EndPosition(nil).Offset+1:]
	fixer.appliedFix = true
	fixer.code = fmt.Sprintf("%s%s%s", pre, replacement, post)
}

func (fixer *AstFixer) fixImports(imp *ast.ImportDeclaration) {
	identifier := ""
	if len(imp.Identifiers) == 0 {
		identifier = imp.Location.String()
	} else {
		identifier = imp.Identifiers[0].Identifier
	}

	libPath := fmt.Sprintf("./standardsV1/%s.cdc", identifier)
	_, err := os.ReadFile(libPath)
	if err == nil && !strings.Contains(imp.Location.String(), "/standardsV1/") {
		fmt.Println("- Using replacement")

		relPath, _ := filepath.Rel(path.Dir(fixer.path), libPath)

		fixer.ReplaceElement(imp,
			fmt.Sprintf("import %s from \"./%s\"", identifier, relPath),
		)
		return
		//panic(relPath)
	}

	if strings.Contains(imp.Location.String(), "/contracts/") {
		newPath := strings.Replace(imp.Location.String(), "/contracts/", "/contractsV1/", 1)
		relPath, _ := filepath.Rel(path.Dir(fixer.path), path.Join(path.Dir(fixer.path), newPath))

		fixer.ReplaceElement(imp,
			fmt.Sprintf("import %s from \"./%s\"", identifier, relPath),
		)
		return
	}

}

func (fixer *AstFixer) fixConformances(composite *ast.CompositeDeclaration) {

	for _, conf := range composite.ConformanceList() {
		if fixer.appliedFix {
			return
		}
		switch conf.Identifier.String() {

		case "MetadataViews":
			if conf.NestedIdentifiers[0].Identifier == "ResolverCollection" {
				fixer.ReplaceElement(conf.Identifier, "ViewResolver")
				break
			}
			if conf.NestedIdentifiers[0].Identifier == "Resolver" {
				fixer.ReplaceElement(conf.Identifier, "ViewResolver")
				break
			}

		//add NonFungibleToken.Collection as conformance if resource implements NonFungibleToken.CollectionPublic
		case "NonFungibleToken":

			if len(conf.NestedIdentifiers) > 0 && conf.NestedIdentifiers[0].Identifier == "CollectionPublic" {
				//check if already fixed
				if !strings.Contains(composite.String(), "NonFungibleToken.Collection, ") {
					fixer.ReplaceElement(conf, "NonFungibleToken.Collection, NonFungibleToken.CollectionPublic")
					break
				}
			}

			//add FungibleToken.Vault as conformance if resource implements FungibleToken.Provider
		case "FungibleToken":

			if len(conf.NestedIdentifiers) > 0 && conf.NestedIdentifiers[0].Identifier == "Provider" {
				//check if already fixed
				if !strings.Contains(composite.String(), "FungibleToken.Vault, ") {
					fixer.ReplaceElement(conf, "FungibleToken.Vault, FungibleToken.Provider")
					break
				}
			}

		}

	}
}

func (fixer *AstFixer) fixSpecialFunction(function *ast.SpecialFunctionDeclaration) {

	if fixer.replaceFunctions {
		fmt.Println("Replacing function with stub: ", function.DeclarationIdentifier().Identifier)
		var block = function.FunctionDeclaration.FunctionBlock

		if block != nil && !strings.Contains(block.String(), "panic(\"stub\")") {
			fixer.ReplaceElement(block, "{\n panic(\"stub\") \n}")
			return
		}
	}
}

func (fixer *AstFixer) fixFunction(function *ast.FunctionDeclaration) {

	//remote legacy `destroy()`
	if function.DeclarationIdentifier().Identifier == "LEGACY_destroy" {
		fixer.ReplaceElement(function, "")
		return
	}

	//add view purity if needed
	if _, ok := fixer.needsPurity[function.DeclarationIdentifier().Identifier]; ok {
		fmt.Println("needs purity")
		if function.Purity != ast.FunctionPurityView {
			function.Purity = ast.FunctionPurityView
			fmt.Println("updating purity")
			fmt.Println(function.String())
			fixer.ReplaceElement(function, function.String())
			return
		}
	}

	if fixer.replaceFunctions {
		fmt.Println("Replacing function with stub: ", function.DeclarationIdentifier().Identifier)
		var block = function.FunctionBlock

		if block != nil && !strings.Contains(block.String(), "panic(\"stub\")") {
			fixer.ReplaceElement(block, "{\n panic(\"stub\") \n}")
			return
		}
	}
}

func (fixer *AstFixer) fixVariableDeclaration(variable *ast.VariableDeclaration) {
	//check access needed

	if requiredAccess, ok := fixer.needsAccess[variable.Identifier.String()]; ok {
		if cast, ok := variable.Value.(*ast.CastingExpression); ok {
			authPrefix := fmt.Sprintf("auth(%s)", requiredAccess.QualifiedString())

			//check if already fixed
			if strings.Contains(cast.TypeAnnotation.String(), authPrefix) {
				return
			}
			replacement := fmt.Sprintf("%s %s", authPrefix, cast.TypeAnnotation.String())
			fixer.ReplaceElement(cast.TypeAnnotation, replacement)
		}
	}
}

func (fixer *AstFixer) fixInvocation(invocation *ast.InvocationExpression) {

	if invocation.InvokedExpression.String() == "MetadataViews.NFTCollectionData" && len(invocation.Arguments) == 7 {
		//remove unneeded parameters
		invocation.Arguments = append(invocation.Arguments[:2], invocation.Arguments[3:]...)
		invocation.Arguments = append(invocation.Arguments[:4], invocation.Arguments[5:]...)

		fixer.ReplaceElement(invocation, invocation.String())
	}
}

func (fixer *AstFixer) walker(element ast.Element) {
	if fixer.appliedFix {
		return
	}
	switch e := element.(type) {

	case *ast.ImportDeclaration:
		fixer.fixImports(e)

	case *ast.CompositeDeclaration:
		fixer.fixConformances(e)

	case *ast.FunctionDeclaration:
		fixer.fixFunction(e)

	case *ast.SpecialFunctionDeclaration:
		fixer.fixSpecialFunction(e)

	case *ast.VariableDeclaration:
		fixer.fixVariableDeclaration(e)

	case *ast.AssignmentStatement:
		break

	case *ast.InvocationExpression:
		fixer.fixInvocation(e)

	}

	element.Walk(fixer.walker)
}

func FindElement(program *ast.Program, position ast.Position, elementType ast.ElementType) ast.Element {
	var finder func(element ast.Element)
	var found ast.Element
	finder = func(element ast.Element) {

		if element.ElementType() == elementType {
			if position.Offset <= element.EndPosition(nil).Offset && position.Offset >= element.StartPosition().Offset {
				found = element
			}
		}
		element.Walk(finder)
	}
	program.Walk(finder)
	return found
}

func AddFunctionToComposite(data string, program *ast.Program, code string, position ast.Position) string {

	element := FindElement(program, position, ast.ElementTypeCompositeDeclaration)
	if element != nil {
		composite := element.(*ast.CompositeDeclaration)
		functions := composite.Members.Functions()
		var endPosition = functions[len(functions)-1].EndPosition(nil)
		pre := data[:endPosition.Offset+1]
		post := data[endPosition.Offset+1:]
		return pre + "\n\n" + code + "\n\n" + post
	}
	return data
}

func AddImportToProgram(data string, location common.Location, program *ast.Program, imported string) string {
	fmt.Println("add import ", imported)
	firstImport := program.ImportDeclarations()[0]
	pre := data[:firstImport.EndPosition(nil).Offset+1]
	post := data[firstImport.EndPosition(nil).Offset+1:]

	newPath := path.Join(path.Dir(location.String()), imported)
	name := path.Base(newPath)
	libPath := fmt.Sprintf("./standardsV1/%s.cdc", name)
	_, err := os.ReadFile(libPath)
	if err == nil {
		newPath = libPath
	}
	relPath, _ := filepath.Rel(path.Dir(location.String()), newPath) //use the Rel function to get the relative path

	return fmt.Sprintf("%s\nimport %s from \"%s\"\n%s", pre, imported, relPath, post)
}

func ReplaceFunction(data string, program *ast.Program, compositeMember *sema.Member, interfaceMember *sema.Member) string {

	element := FindElement(program, compositeMember.Identifier.StartPosition(), ast.ElementTypeFunctionDeclaration)

	if element != nil {
		fmt.Println("element")
		composite := element.(*ast.FunctionDeclaration)
		endPosition := element.EndPosition(nil)
		if composite.FunctionBlock != nil {
			endPosition = composite.FunctionBlock.StartPosition()
		}

		pre := data[:composite.StartPosition().Offset]
		post := data[endPosition.Offset+1:]
		inner := data[composite.StartPosition().Offset : endPosition.Offset+1]

		code := strings.ReplaceAll(interfaceMember.TypeAnnotation.QualifiedString(), "fun", fmt.Sprintf("fun %s", interfaceMember.Identifier.String()))
		code = fmt.Sprintf("access(%s) ", interfaceMember.Access.QualifiedString()) + code
		if composite.FunctionBlock != nil {
			code = code + "{"
		}

		fmt.Println(code)
		fmt.Println(inner)

		return pre + code + post
	}
	panic("cant replace")
	return data
}
