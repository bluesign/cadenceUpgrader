package tools

import (
	"fmt"
	"github.com/onflow/cadence/runtime/ast"
	"github.com/onflow/cadence/runtime/common"
	"github.com/onflow/cadence/runtime/parser"
	"github.com/onflow/cadence/runtime/sema"
	"github.com/onflow/cadence/runtime/stdlib"
	"os"
	"strings"
)

var checkers = map[common.Location]*sema.Checker{}
var codes = map[common.Location][]byte{}

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

func PrepareProgramFromFile(location common.StringLocation, codes map[common.Location][]byte) (*ast.Program, func(error)) {
	code, err := os.ReadFile(string(location))
	program, must := PrepareProgram(code, location, codes)
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
		AccessCheckMode: sema.AccessCheckModeStrict,
		ImportHandler: func(
			checker *sema.Checker,
			importedLocation common.Location,
			_ ast.Range,
		) (sema.Import, error) {

			if importedLocation == stdlib.CryptoCheckerLocation {
				cryptoChecker := stdlib.CryptoChecker()
				return sema.ElaborationImport{
					Elaboration: cryptoChecker.Elaboration,
				}, nil
			}

			stringLocation, ok := importedLocation.(common.StringLocation)
			if !ok {

				return nil, &sema.CheckerError{
					Location: checker.Location,
					Codes:    codes,
					Errors: []error{
						fmt.Errorf("cannot import `%s`. only files are supported", importedLocation),
					},
				}
			}

			importedChecker, ok := checkers[importedLocation]
			if !ok {
				importedProgram, _ := PrepareProgramFromFile("v1standards/"+stringLocation+".cdc", codes)
				importedChecker, _ = checker.SubChecker(importedProgram, importedLocation)
				importedChecker.Check()
				checkers[importedLocation] = importedChecker
			}

			return sema.ElaborationImport{
				Elaboration: importedChecker.Elaboration,
			}, nil
		},
		AttachmentsEnabled: true,
	}
}

func PrepareChecker(
	program *ast.Program,
	location common.Location,
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
	code       string

	capabilityIndex int

	needsPurity map[string]bool
	needsAccess map[string]sema.Access
}

func NewAstFixer(code string) *AstFixer {
	program, err := parser.ParseProgram(nil, []byte(code), parser.Config{})
	if err != nil {
		panic(err)
	}
	return &AstFixer{
		appliedFix:      false,
		program:         program,
		code:            code,
		capabilityIndex: 0,

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

func (fixer *AstFixer) CheckAndFix() (bool, string) {
	fixer.updateProgram()
	var checker *sema.Checker
	var must func(error)
	memberAccountAccess := make(map[common.Location]map[common.Location]struct{})
	location := common.NewStringLocation(nil, os.Args[1])
	standardLibraryValues := stdlib.DefaultStandardLibraryValues(nil)

	program, must := PrepareProgram([]byte(fixer.code), location, codes)
	checker, _ = PrepareChecker(
		program,
		location,
		codes,
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
		switch v := e.(type) {
		case *sema.NotDeclaredMemberError:

			if strings.HasSuffix(v.Type.String(), "&Account") {
				fmt.Println("Fixing &Account")

				switch v.Expression.Identifier.String() {
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
			fmt.Println("Fixing Missing Declarations")

			if v.Name == "ViewResolver" {
				//add import
				fmt.Println("Adding import")
				fixer.code = AddImportToProgram(fixer.code, program, "ViewResolver")
				fixer.appliedFix = true
				break
			}

			if v.Name == "MetadataViews.Resolver" {
				fmt.Println(fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1])
				fixer.ReplaceElement(v, "ViewResolver")
				break
			}

			fixer.appliedFix = false

		case *sema.InvalidInterfaceTypeError:
			fmt.Println("Fixing Interface Type")

			if v.ExpectedType.IsResourceType() {
				fixer.ReplaceElement(v, "@"+v.ExpectedType.QualifiedString())
			} else {
				fixer.ReplaceElement(v, v.ExpectedType.QualifiedString())
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
			fmt.Println("Fixing Purity")
			elem := FindElement(program, v.StartPosition(), ast.ElementTypeInvocationExpression)
			invocation := elem.(*ast.InvocationExpression)
			if invocation != nil {
				fmt.Println(invocation.String())
				invoked := strings.Split(invocation.InvokedExpression.String(), ".")
				if invoked[1] != "append" {
					if _, ok := fixer.needsPurity[invoked[1]]; !ok {
						fmt.Println("setting to fix purity", invoked[1])
						fixer.needsPurity[invoked[1]] = true
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

		case *sema.TypeMismatchError:
			fmt.Println("Fixing Casting")
			inner := fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1]
			_, isCasting := v.Expression.(*ast.CastingExpression)
			fmt.Println(inner)

			if isCasting {
				replacement := strings.ReplaceAll(inner, v.ActualType.QualifiedString(), v.ExpectedType.QualifiedString())
				fixer.ReplaceElement(v, replacement)

			}

			/*else {
				//we cast
				replacement := "((" + inner + ") as! " + v.ExpectedType.QualifiedString() + ")"
				fixer.ReplaceElement(v, replacement)
			}*/

		case *sema.ConformanceError:
			fmt.Println("Fixing Conformances")
			if len(v.MissingMembers) > 0 {
				missing := v.MissingMembers[0]
				if missing.DeclarationKind == common.DeclarationKindFunction {
					newCode := strings.ReplaceAll(missing.TypeAnnotation.QualifiedString(), "fun", fmt.Sprintf("fun %s", missing.Identifier.String()))
					newCode = fmt.Sprintf("access(%s) ", missing.Access.String()) + newCode

					if missing.Identifier.String() == "createEmptyCollection" {
						newCode = newCode + "{\n return <-create Collection() \n}"
					} else if missing.Identifier.String() == "getLength" {
						newCode = newCode + "{\n return self.ownedNFTs.length \n}"
					} else {
						newCode = newCode + "{\n panic(\"implement me\") \n}"
					}

					fixer.code = AddFunctionToComposite(fixer.code, program, newCode, v.StartPosition())
					fixer.appliedFix = true
				}
			}

			if len(v.MemberMismatches) > 0 {
				mismatch := v.MemberMismatches[0]
				compositeContract := strings.Split(mismatch.CompositeMember.ContainerType.QualifiedString(), ".")[0]
				interfaceContract := strings.Split(mismatch.InterfaceMember.ContainerType.QualifiedString(), ".")[0]

				if interfaceContract != compositeContract {
					fixer.code = ReplaceFunction(fixer.code, program, mismatch.CompositeMember, mismatch.InterfaceMember)
					fixer.appliedFix = true
				} else {
					//reverse
					fixer.code = ReplaceFunction(fixer.code, program, mismatch.InterfaceMember, mismatch.CompositeMember)
					fixer.appliedFix = true
				}

			}

		default:
			fmt.Println("ERR:", v)
			fmt.Printf("%T\n", v)
			fixer.appliedFix = false

		}
		if fixer.appliedFix {
			return true, fixer.code
		}
	}

	return fixer.appliedFix, fixer.code

}

func (fixer *AstFixer) ReplaceElement(old ast.HasPosition, replacement string) {
	pre := fixer.code[:old.StartPosition().Offset]
	post := fixer.code[old.EndPosition(nil).Offset+1:]
	fixer.appliedFix = true
	fixer.code = fmt.Sprintf("%s%s%s", pre, replacement, post)
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
		}
	}
}

func (fixer *AstFixer) fixFunction(function *ast.FunctionDeclaration) {

	//remote legacy `destroy()`
	if function.DeclarationIdentifier().Identifier == "LEGACY_destroy" {
		fixer.ReplaceElement(function, "")
	}

	//add view purity if needed
	if _, ok := fixer.needsPurity[function.DeclarationIdentifier().Identifier]; ok {
		fmt.Println("needs purity")

		if function.Purity != ast.FunctionPurityView {
			function.Purity = ast.FunctionPurityView
			fmt.Println("updating purity")
			fmt.Println(function.String())
			fixer.ReplaceElement(function, function.String())
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

	case *ast.CompositeDeclaration:
		fmt.Println("Fixing Conformances")
		fixer.fixConformances(e)

	case *ast.FunctionDeclaration:
		fmt.Println("Fixing Functions")
		fixer.fixFunction(e)

	case *ast.VariableDeclaration:
		fmt.Println("Fixing Variables")
		fixer.fixVariableDeclaration(e)

	case *ast.AssignmentStatement:
		break

	case *ast.InvocationExpression:
		fmt.Println("Fixing Invocations")
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

func AddImportToProgram(data string, program *ast.Program, imported string) string {
	firstImport := program.ImportDeclarations()[0]
	pre := data[:firstImport.EndPosition(nil).Offset+1]
	post := data[firstImport.EndPosition(nil).Offset+1:]
	return pre + "\n" + "import \"" + imported + "\"" + "\n" + post
}

func ReplaceFunction(data string, program *ast.Program, compositeMember *sema.Member, interfaceMember *sema.Member) string {

	element := FindElement(program, compositeMember.Identifier.StartPosition(), ast.ElementTypeFunctionDeclaration)

	if element != nil {
		composite := element.(*ast.FunctionDeclaration)
		endPosition := element.EndPosition(nil)
		if composite.FunctionBlock != nil {
			endPosition = composite.FunctionBlock.StartPosition()
		}

		pre := data[:composite.StartPosition().Offset]
		post := data[endPosition.Offset+1:]

		code := strings.ReplaceAll(interfaceMember.TypeAnnotation.QualifiedString(), "fun", fmt.Sprintf("fun %s", interfaceMember.Identifier.String()))
		code = fmt.Sprintf("access(%s) ", interfaceMember.Access.QualifiedString()) + code
		if composite.FunctionBlock != nil {
			code = code + "{"
		}

		return pre + code + post
	}
	return data
}
