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

		//processor
		fixed, code = astFixer.Process(spath)
		if fixed {
			continue
		}

		//panic("deniz")
		break

	}
	output := PrettyCode(string(code), 100, true)
	fmt.Println("formatted")

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
	fmt.Println(err)
	must(err)

	return checker, must
}

type AstFixer struct {
	appliedFix       bool
	program          *ast.Program
	checkers         map[common.Location]*sema.Checker
	codes            map[common.Location][]byte
	addedImports     map[string]bool
	currentChecker   *sema.Checker
	contractName     string
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
		//panic(err)

	}

	return &AstFixer{
		appliedFix:       false,
		program:          program,
		codes:            make(map[common.Location][]byte),
		checkers:         make(map[common.Location]*sema.Checker),
		addedImports:     make(map[string]bool),
		code:             code,
		path:             path,
		replaceFunctions: replaceFunctions,
		capabilityIndex:  0,

		needsPurity: make(map[string]bool),
		needsAccess: make(map[string]sema.Access),
	}
}

func (fixer *AstFixer) updateProgram(location common.Location) func(error) {
	must := mustClosure(location, fixer.codes)

	program, err := parser.ParseProgram(nil, []byte(fixer.code), parser.Config{})
	fixer.codes[location] = []byte(fixer.code)
	must(err)

	fixer.program = program
	fixer.appliedFix = false

	return must
}

func (fixer *AstFixer) WalkAndFix() (bool, string) {
	fixer.updateProgram(common.NewStringLocation(nil, fixer.path))
	fixer.program.Walk(fixer.walker)
	return fixer.appliedFix, fixer.code
}

func (fixer *AstFixer) typeToString(t sema.Type) string {
	prefix := ""
	if t.IsResourceType() {
		prefix = "@"
	}
	return prefix + t.QualifiedString()
}

func (fixer *AstFixer) findExpressionType(e ast.Expression) sema.Type {

	checker := fixer.currentChecker
	if checker == nil || checker.Elaboration == nil {
		return nil
	}
	switch ex := e.(type) {
	case *ast.CreateExpression:
		if checker.Elaboration.InvocationExpressionTypes(ex.InvocationExpression).ReturnType == nil {
			return nil
		}
		fmt.Println("type: ", checker.Elaboration.InvocationExpressionTypes(ex.InvocationExpression).ReturnType.QualifiedString())
		return checker.Elaboration.InvocationExpressionTypes(ex.InvocationExpression).ReturnType

	case *ast.InvocationExpression:
		if checker.Elaboration.InvocationExpressionTypes(ex).ReturnType == nil {
			return nil
		}
		fmt.Println("type: ", checker.Elaboration.InvocationExpressionTypes(ex).ReturnType.QualifiedString())
		return checker.Elaboration.InvocationExpressionTypes(ex).ReturnType

	case *ast.ForceExpression:
		t := fixer.findExpressionType(ex.Expression)
		switch it := t.(type) {
		case *sema.OptionalType:
			return it.Type
		}
		return t

	case *ast.CastingExpression:
		return checker.Elaboration.CastingExpressionTypes(ex).TargetType

	case *ast.IndexExpression:
		return checker.Elaboration.IndexExpressionTypes(ex).ResultType
	case *ast.BinaryExpression:
		return checker.Elaboration.BinaryExpressionTypes(ex).ResultType
	}

	return nil
}

func (fixer *AstFixer) Process(path string) (bool, string) {

	fixer.appliedFix = true
	for fixer.appliedFix {
		fixer.WalkAndFix()
		if fixer.appliedFix {
			continue
		}
		fixer.CheckAndFixOne(path)
	}

	return fixer.appliedFix, fixer.code
}

func (fixer *AstFixer) CheckAndFixOne(path string) (bool, string) {
	var checker *sema.Checker
	must := fixer.updateProgram(common.NewStringLocation(nil, path))

	fixer.codes = make(map[common.Location][]byte)
	fixer.checkers = make(map[common.Location]*sema.Checker)

	memberAccountAccess := make(map[common.Location]map[common.Location]struct{})
	standardLibraryValues := stdlib.DefaultStandardLibraryValues(nil)

	checker, _ = PrepareChecker(
		fixer.program,
		common.NewStringLocation(nil, path),
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
		fmt.Printf("T: %T V: %s\n", e, e)

		switch v := e.(type) {

		case *sema.InvalidUnaryOperandError:
			//ignore
			break

		case *sema.NotDeclaredMemberError:

			if parser.IsHardKeyword(v.Expression.Identifier.String()) {
				fixer.ReplaceElement(v.Expression.Identifier, "_"+v.Expression.Identifier.String())
			}

			if strings.HasSuffix(v.Type.String(), "&Account") {
				fmt.Println("Fixing &Account")

				switch v.Expression.Identifier.String() {
				case "storageUsed":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.used")
				case "storageCapacity":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.capacity")
				case "save":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.save")
				case "copy":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.copy")
				case "load":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.load")
				case "borrow":
					fixer.ReplaceElement(v.Expression.Identifier, "storage.borrow")
				case "getCapability":
					elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeInvocationExpression)
					invocation := elem.(*ast.InvocationExpression)
					replacement := strings.ReplaceAll(invocation.String(), "getCapability", "capabilities.get")

					if !strings.Contains(invocation.String(), "<") {
						replacement = strings.ReplaceAll(invocation.String(), "getCapability", "capabilities.get_<YOUR_TYPE>")
						pos := v.EndPosition(nil)
						next_invocation, _ := FindElement(fixer.program, pos, ast.ElementTypeInvocationExpression).(*ast.InvocationExpression)

						search := 100
						for next_invocation != nil && invocation.String() == next_invocation.String() && search > 0 {
							pos.Offset += 1
							search--
							next_invocation, _ = FindElement(fixer.program, pos, ast.ElementTypeInvocationExpression).(*ast.InvocationExpression)
						}
						fmt.Println("next:", next_invocation)

						if next_invocation != nil && strings.HasSuffix(next_invocation.InvokedExpression.String(), ".borrow") {
							replacement = strings.ReplaceAll(invocation.String(),
								"getCapability",
								fmt.Sprintf("capabilities.get<%s>", next_invocation.TypeArguments[0].String()),
							)
						}
					}

					//panic("s")

					fixer.ReplaceElement(
						elem,
						replacement,
					)
				case "link":
					endPos := v.EndPos
					endPos.Offset = endPos.Offset + 1
					elem := FindElement(fixer.program, endPos, ast.ElementTypeInvocationExpression).(*ast.InvocationExpression)
					if elem.InvokedExpression.String() == "self.account.link" {
						var publicPath = elem.Arguments[0].String()
						var storagePath = elem.Arguments[1].String()
						var linkType = elem.TypeArguments[0].String()
						fixer.capabilityIndex++
						data := fmt.Sprintf("var capability_%d = self.account.capabilities.storage.issue<%s>(%s)\n", fixer.capabilityIndex, linkType, storagePath)
						data = data + fmt.Sprintf("self.account.capabilities.publish(capability_%d , at:%s)\n", fixer.capabilityIndex, publicPath)
						declare, isDeclare := FindElement(fixer.program, endPos, ast.ElementTypeVariableDeclaration).(*ast.VariableDeclaration)
						assign, isAssign := FindElement(fixer.program, endPos, ast.ElementTypeAssignmentStatement).(*ast.AssignmentStatement)
						if isDeclare {
							predeclared := strings.Split(declare.String(), declare.Transfer.Operation.Operator())[0]
							data = data + fmt.Sprintf("%s %s capability_%d\n", predeclared, declare.Transfer.Operation.Operator(), fixer.capabilityIndex)
							fixer.ReplaceElement(declare, data)
						} else if isAssign {
							data = data + fmt.Sprintf("%s %s capability_%d\n", assign.Target.String(), assign.Transfer.Operation.Operator(), fixer.capabilityIndex)
							fixer.ReplaceElement(assign, data)
						} else {
							fixer.ReplaceElement(elem, data)
						}

					}
				}
			}

		case *sema.NotDeclaredError:
			fmt.Println("Fixing Missing Declarations:", v.Name)

			if parser.IsHardKeyword(v.Name) {
				fixer.ReplaceElement(v, "_"+v.Name)
				break
			}

			if v.Name == "ViewResolver" {
				//add import
				if _, ok := fixer.addedImports["ViewResolver"]; !ok {
					fixer.code = AddImportToProgram(fixer.code, checker.Location, fixer.program, "ViewResolver")
					fixer.addedImports["ViewResolver"] = true
					fixer.appliedFix = true
					break
				}

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

		case *sema.InvalidNestedDeclarationError:
			inner := fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1]
			fmt.Println("InvalidNestedDeclarationError", inner)
			if v.NestedDeclarationKind != common.DeclarationKindEnum {
				fixer.ReplaceElement(v, "interface "+inner)
			}

		case *sema.InvalidInterfaceTypeError:
			fmt.Println("Fixing Interface Type")

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

			elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeInvocationExpression)
			if elem != nil {
				expression := elem.(*ast.InvocationExpression)
				if strings.HasSuffix(expression.InvokedExpression.String(), "createEmptyCollection") {
					pre := fixer.code[:expression.ArgumentsStartPos.Offset+1]
					post := fixer.code[expression.ArgumentsStartPos.Offset+1:]

					parts := strings.Split(expression.InvokedExpression.String(), ".")
					target := parts[0] + "."
					if target == "self." {
						target = ""
					}
					fixer.code = pre + fmt.Sprintf("nftType: Type<@%sCollection>()", target) + post
					fixer.appliedFix = true
				}

				if strings.HasSuffix(expression.InvokedExpression.String(), "createEmptyVault") {
					pre := fixer.code[:expression.ArgumentsStartPos.Offset+1]
					post := fixer.code[expression.ArgumentsStartPos.Offset+1:]
					parts := strings.Split(expression.InvokedExpression.String(), ".")
					target := parts[0] + "."
					if target == "self." {
						target = ""
					}

					fixer.code = pre + fmt.Sprintf("vaultType: Type<@%sVault>()", target) + post
					fixer.appliedFix = true
				}

			}

		case *sema.PurityError:
			fmt.Println("\nFixing Purity")
			elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeInvocationExpression)
			if elem == nil {
				//TODO: check me
				break
			}
			invocation := elem.(*ast.InvocationExpression)
			if invocation != nil {
				fmt.Println(invocation.String())
				invoked := strings.Split(invocation.InvokedExpression.String(), ".")

				if len(invoked) > 1 {
					if invoked[len(invoked)-1] == "append" {
						//TODO: maybe concat

					} else {
						if _, ok := fixer.needsPurity[invoked[len(invoked)-1]]; !ok {
							fmt.Println("setting to fix purity: ", invoked[len(invoked)-1])
							fixer.needsPurity[invoked[len(invoked)-1]] = true
							fixer.appliedFix = true
						}
					}
				}

				if len(invoked) == 1 {
					//struct
					structName := invoked[0]
					if _, ok := fixer.needsPurity[structName]; !ok {
						fmt.Println("setting to fix purity for struct: ", structName)
						fixer.needsPurity[structName] = true
						fixer.appliedFix = true
					}
				}
			}

		case *sema.UnauthorizedReferenceAssignmentError:
			fmt.Println("Fixing Reference Entitlements")
			elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeAssignmentStatement)
			if elem == nil {
				//TODO: handle me
				break
			}
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

			}

		case *sema.NestedReferenceError:
			fmt.Println("Fixing Nested Reference")
			elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeCastingExpression)
			casting := elem.(*ast.CastingExpression)
			fixer.ReplaceElement(v, casting.Expression.String()[1:])

		case *sema.IncorrectArgumentLabelError:
			fmt.Println("Fixing Labels")
			replacement := v.ExpectedArgumentLabel
			if v.ExpectedArgumentLabel != "" {
				replacement = replacement + ":"
			}
			fixer.ReplaceElement(v, replacement)

		case *sema.MissingArgumentLabelError:
			fmt.Println("Missing Labels")
			replacement := v.ExpectedArgumentLabel
			if v.ExpectedArgumentLabel != "" {
				replacement = replacement + ":"
			}
			fixer.InsertElement(v, replacement)

		case *sema.TypeMismatchWithDescriptionError:
			inner := fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1]
			fmt.Println("TypeMismatchWithDescriptionError", v.ActualType, v.ExpectedTypeDescription, inner)
			//panic("d")

		case *sema.InvalidTypeArgumentCountError:
			inner := fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1]
			fmt.Println("InvalidTypeArgumentCountError", v.TypeArgumentCount, inner)
			if v.TypeParameterCount == 0 && v.TypeArgumentCount == 1 {
				//remove
				fixer.ReplaceElement(v, "")
				fixer.code = strings.ReplaceAll(fixer.code, ".borrow<>", ".borrow")

			}
		case *sema.TypeMismatchError:
			inner := fixer.code[v.StartPosition().Offset : v.EndPosition(nil).Offset+1]
			fmt.Println("TypeMismatchError", v.ActualType.QualifiedString(), v.ExpectedType.QualifiedString(), inner)

			if v.ActualType.QualifiedString() == v.ExpectedType.QualifiedString() {
				break
			}
			elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeCastingExpression)
			if elem != nil {
				casting, isCasting := elem.(*ast.CastingExpression)
				if isCasting {
					fmt.Println("Fixing Casting")
					replacement := v.ExpectedType.QualifiedString()

					if _, ok := casting.Expression.(*ast.ReferenceExpression); ok {
						replacement = v.ActualType.QualifiedString()
						if !strings.HasPrefix(replacement, "&") {
							replacement = "&" + replacement
						}
					}
					if casting.TypeAnnotation.String() != replacement {
						fixer.ReplaceElement(casting.TypeAnnotation, replacement)
					}
					//panic("s")
					break
				}
			}

			if v.ActualType.QualifiedString() == v.ExpectedType.QualifiedString()+"?" {
				if !strings.Contains(inner, "??") {
					fmt.Println("forcing")
					fixer.ReplaceElement(v, inner+"!")
				}
			}

			if v.ActualType.QualifiedString() == "&"+v.ExpectedType.QualifiedString() {
				fmt.Println("Dereferencing")
				fixer.ReplaceElement(v, "*"+inner)
				break
			}

		case *sema.TypeAnnotationRequiredError:
			fmt.Println("TypeAnnotationRequiredError", v)
			if strings.Contains(v.Cause, "cannot infer type from reference expression") {
				elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeCastingExpression)
				casting, isCasting := elem.(*ast.CastingExpression)
				if isCasting && (casting.Operation == ast.OperationForceCast || casting.Operation == ast.OperationFailableCast) {
					casting.Operation = ast.OperationCast
					fixer.ReplaceElement(casting, casting.String())
				}
				break
			}
			if strings.Contains(v.Cause, "cannot infer type from dictionary") {
				//	elem := FindElement(program, v.StartPosition(), ast.ElementTypeDictionaryExpression)
				//dictionary, ok := elem.(*ast.DictionaryExpression)
				if ok {
					//fixer.ReplaceElement(dictionary, fmt.Sprintf("(%s as {String:String})", dictionary.String()))
				}
				break
			}

		case *sema.InvalidNestedResourceMoveError:
			fmt.Println("ConformanceError", v)

			elem := FindElement(fixer.program, v.StartPosition(), ast.ElementTypeCastingExpression)
			if elem == nil {
				//TODO: check me
				break
			}
			casting, isCasting := elem.(*ast.CastingExpression)
			if isCasting {
				fmt.Println("Fixing nested resource move")

				if referenceExpression, ok := casting.Expression.(*ast.ReferenceExpression); ok {
					if forced, ok := referenceExpression.Expression.(*ast.ForceExpression); ok {
						replace := fixer.code[forced.StartPosition().Offset:forced.EndPosition(nil).Offset]
						fixer.ReplaceElement(forced, replace)
					}
				}

			}

		case *sema.ConformanceError:
			fmt.Println("ConformanceError", v)

			if len(v.MissingMembers) > 0 {
				fmt.Println("Fixing Conformances")
				missing := v.MissingMembers[0]
				if missing.DeclarationKind == common.DeclarationKindFunction {
					newCode := strings.ReplaceAll(missing.TypeAnnotation.QualifiedString(), "fun", fmt.Sprintf("fun %s", missing.Identifier.String()))
					newCode = fmt.Sprintf("access(%s) ", missing.Access.String()) + newCode

					fmt.Println(v.CompositeDeclaration.DeclarationIdentifier().Identifier)
					fmt.Println(v.InterfaceType.QualifiedString())
					if missing.Identifier.String() == "createEmptyCollection" {
						if v.InterfaceType.QualifiedString() == "NonFungibleToken.Collection" {
							newCode = newCode + fmt.Sprintf("{\n return <-create %s() \n}", v.CompositeDeclaration.DeclarationIdentifier().Identifier)
						} else {
							newCode = newCode + "{\n return <-create Collection() \n}"
						}

					} else if missing.Identifier.String() == "getLength" {
						newCode = newCode + "{\n return self.ownedNFTs.length \n}"
					} else if missing.Identifier.String() == "createEmptyVault" {
						newCode = newCode + "{\n return <-create Vault(balance:0.0) \n}"
					} else if missing.Identifier.String() == "isAvailableToWithdraw" {
						newCode = newCode + "{\n return self.balance>=amount \n}"
					} else {
						newCode = newCode + "{\n panic(\"implement me\") \n}"
					}

					fixer.code = AddFunctionToComposite(fixer.code, fixer.program, newCode, v.StartPosition())
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

					fmt.Println(interfaceContract)
					libPath := fmt.Sprintf("./standardsV1/%s.cdc", interfaceContract)
					_, err := os.ReadFile(libPath)
					fmt.Println("different contract")
					if err == nil {
						fmt.Println("fixing to stardard")
						oldcode := fixer.code
						fixer.code = ReplaceFunction(fixer.code, fixer.program, mismatch.CompositeMember, mismatch.InterfaceMember, false)
						fixer.appliedFix = fixer.code != oldcode
					}
					break
				} else {
					fmt.Println("same contract")
					//reverse
					oldcode := fixer.code
					fixer.code = ReplaceFunction(fixer.code, fixer.program, mismatch.InterfaceMember, mismatch.CompositeMember, true)
					fixer.appliedFix = fixer.code != oldcode
					break
				}

			}

		default:
			fmt.Println("ERR:", v)
			fmt.Printf("%T\n", v)
		}

		if fixer.appliedFix {
			break
		}
	}

	fixer.currentChecker = checker

	return fixer.appliedFix, fixer.code

}

func (fixer *AstFixer) ReplaceElement(old ast.HasPosition, replacement string) {
	fmt.Println("find:", fixer.code[old.StartPosition().Offset:old.EndPosition(nil).Offset+1])
	fmt.Println("replace:", replacement)
	pre := fixer.code[:old.StartPosition().Offset]
	post := fixer.code[old.EndPosition(nil).Offset+1:]
	fixer.appliedFix = true
	fixer.code = fmt.Sprintf("%s%s%s", pre, replacement, post)
}

func (fixer *AstFixer) InsertElement(old ast.HasPosition, replacement string) {
	fmt.Println("find:", fixer.code[old.StartPosition().Offset:old.EndPosition(nil).Offset+1])
	fmt.Println("insert:", replacement)
	pre := fixer.code[:old.StartPosition().Offset]
	post := fixer.code[old.StartPosition().Offset:]
	fixer.appliedFix = true
	fixer.code = fmt.Sprintf("%s%s%s", pre, replacement, post)
}
func (fixer *AstFixer) AppendElement(old ast.HasPosition, replacement string) {
	fmt.Println("find:", fixer.code[old.StartPosition().Offset:old.EndPosition(nil).Offset+1])
	fmt.Println("append:", replacement)
	pre := fixer.code[:old.EndPosition(nil).Offset+1]
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

		fixer.addedImports[identifier] = true

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

	if composite.CompositeKind == common.CompositeKindContract {
		fixer.contractName = composite.Identifier.Identifier
	}

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
		//fix INFT
		case "NonFungibleToken":
			if len(conf.NestedIdentifiers) > 0 && conf.NestedIdentifiers[0].Identifier == "INFT" {
				fixer.ReplaceElement(conf.NestedIdentifiers[0], "NFT")
				break
			}

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
	//add view purity if needed
	composite, ok := FindElement(fixer.program, function.StartPosition(), ast.ElementTypeCompositeDeclaration).(*ast.CompositeDeclaration)
	if ok {
		if _, ok := fixer.needsPurity[composite.Identifier.Identifier]; ok {
			if function.FunctionDeclaration.Purity != ast.FunctionPurityView {
				function.FunctionDeclaration.Purity = ast.FunctionPurityView
				fmt.Println("updating purity")
				fixer.InsertElement(function, "view ")
				return
			}
		}
	}

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
		fmt.Println("needsPurity:", function.DeclarationIdentifier().Identifier)

		if function.Purity != ast.FunctionPurityView {
			function.Purity = ast.FunctionPurityView
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

	if strings.HasSuffix(invocation.InvokedExpression.String(), ".borrowViewResolver") {
		elem := FindElement(fixer.program, invocation.EndPosition(nil), ast.ElementTypeForceExpression)
		if elem == nil {
			fixer.AppendElement(invocation, "!")
		}
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
		if len(functions) > 1 {
			var endPosition = functions[len(functions)-1].EndPosition(nil)
			pre := data[:endPosition.Offset+1]
			post := data[endPosition.Offset+1:]
			return pre + "\n\n" + code + "\n\n" + post
		} else {
			//panic("d")
			fields := composite.Members.Fields()
			if len(fields) > 0 {
				var endPosition = fields[len(fields)-1].EndPosition(nil)
				pre := data[:endPosition.Offset+1]
				post := data[endPosition.Offset+1:]
				return pre + "\n\n" + code + "\n\n" + post
			} else {
				//TODO: handle me
				var endPosition = composite.EndPosition(nil)
				pre := data[:endPosition.Offset]
				post := data[endPosition.Offset:]
				return pre + "\n\n" + code + "\n\n" + post
				fmt.Println("TODO: handle me")
			}

		}

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

func ReplaceFunction(data string, program *ast.Program, compositeMember *sema.Member, interfaceMember *sema.Member, same bool) string {

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

		if same && !strings.Contains(code, "view") && strings.Contains(inner, "view") {
			return data
		}

		return pre + code + post
	}
	//TODO: handle : panic("cant replace")
	return data
}
