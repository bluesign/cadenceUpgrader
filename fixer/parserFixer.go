package fixer

import (
	"fmt"
	"github.com/onflow/cadence/runtime/ast"
	"github.com/onflow/cadence/runtime/parser"
	"strings"
)

type ParseFixer struct {
	appliedFix   bool
	program      *ast.Program
	path         string
	code         string
	replacements map[string]string
}

func NewParseFixer(path string, code string) *ParseFixer {
	return &ParseFixer{
		appliedFix: false,
		program:    nil,
		path:       path,
		code:       code,
	}
}

func (fixer *ParseFixer) ReplaceElement(old ast.HasPosition, replacement string) {
	pre := fixer.code[:old.StartPosition().Offset]
	post := fixer.code[old.EndPosition(nil).Offset+1:]
	fixer.code = fmt.Sprintf("%s%s%s", pre, replacement, post)
	fixer.appliedFix = true
}

func (fixer *ParseFixer) ParseAndFix() (bool, string, *ast.Program) {
	program, err := parser.ParseProgram(nil, []byte(fixer.code), parser.Config{})
	if err == nil {
		return false, fixer.code, program
	}
	for _, parseError := range err.(parser.Error).Errors {
		switch v := parseError.(type) {

		case *parser.SyntaxErrorWithSuggestedReplacement:
			fmt.Println("Applying suggestion: \n- ", v.SuggestedFix)
			fmt.Println(v.SuggestedFix)

			if v.SuggestedFix == "access(all)" {
				v.SuggestedFix = "access(TMP_ENTITLEMENT_OWNER)"
			}
			fixer.ReplaceElement(v, v.SuggestedFix)

		case *parser.CustomDestructorError:
			fmt.Println("Renaming old destructor")
			fixer.ReplaceElement(v, "access(self) fun LEGACY_d")

		case *parser.RestrictedTypeError:
			fmt.Println("Removing type restriction")
			pre := fixer.code[:v.StartPos.Offset-1]
			if strings.HasSuffix(pre, "AnyResource") {
				fmt.Println(pre)
				post := fixer.code[v.StartPos.Offset-1:]
				pre = pre[:len(pre)-11]
				fixer.code = pre + post

			} else if strings.HasSuffix(pre, "AnyStruct") {
				fmt.Println(pre)
				post := fixer.code[v.StartPos.Offset-1:]
				pre = pre[:len(pre)-9]
				fixer.code = pre + post
			} else {
				post := fixer.code[v.EndPos.Offset:]
				post = post[strings.Index(post, "}")+1:]
				fixer.code = pre + post
			}
			fixer.appliedFix = true

		case *parser.MissingCommaInParameterListError:
			pre := fixer.code[:v.StartPosition().Offset]
			post := fixer.code[v.EndPosition(nil).Offset:]
			fmt.Println(pre)
			fixer.code = pre + "," + post
			fixer.appliedFix = true
			break

		case *parser.SyntaxError:

			if strings.Contains(v.Message, "`pub(set)` is no longer a valid access keyword") {
				fmt.Println("fix pub(set)")
				pre := fixer.code[:v.StartPosition().Offset+3]
				post := fixer.code[v.EndPosition(nil).Offset+8:]
				fixer.code = pre + post
				fixer.appliedFix = true
				break
			}
			if strings.Contains(v.Message, "expected identifier for parameter name") {
				fmt.Println("fix keyword")
				fmt.Println(v.Message)
				pre := fixer.code[:v.StartPosition().Offset]
				post := fixer.code[v.EndPosition(nil).Offset:]
				fixer.code = pre + "_" + post
				fixer.appliedFix = true
				break
			}
			if strings.Contains(v.Message, "expected identifier after start of variable declaration, got keyword") {
				fmt.Println("fix keyword")
				fmt.Println(v.Message)
				pre := fixer.code[:v.StartPosition().Offset]
				post := fixer.code[v.EndPosition(nil).Offset:]
				fixer.code = pre + "_" + post
				fixer.appliedFix = true
				break
			}

			if strings.Contains(v.Message, "expected identifier after start of function declaration, got keyword") {
				fmt.Println("fix keyword")
				fmt.Println(v.Message)
				pre := fixer.code[:v.StartPosition().Offset]
				post := fixer.code[v.EndPosition(nil).Offset:]
				fixer.code = pre + "_" + post
				fixer.appliedFix = true
				break
			}

			if strings.Contains(v.Message, "expected identifier for argument label") {
				fmt.Println("fix keyword")
				fmt.Println(v.Message)
				pre := fixer.code[:v.StartPosition().Offset]
				post := fixer.code[v.EndPosition(nil).Offset:]
				fixer.code = pre + "_" + post
				fixer.appliedFix = true
				break
			}
			if strings.Contains(v.Message, "expected authorization (entitlement list)") {
				fmt.Println("fix auth")

				pre := fixer.code[:v.StartPosition().Offset-5]
				post := fixer.code[v.EndPosition(nil).Offset:]
				fixer.code = pre + post
				fixer.appliedFix = true
				break
			}

			if strings.Contains(v.Message, "expected token ')'") {
				//check function change
				fmt.Println("fix fun")
				start := v.StartPosition().Offset

				for fixer.code[start] != '(' {
					start = start - 1
				}
				pre := fixer.code[:start]
				post := fixer.code[start:]
				fixer.code = pre + "fun" + post
				fixer.appliedFix = true
				break
				//panic("s")
			}

			if strings.Contains(v.Message, "unexpected token in type: ')'") {
				//check function change
				fmt.Println("fix fun2")
				start := v.StartPosition().Offset
				for fixer.code[start] != '(' {
					start = start - 1
				}
				pre := fixer.code[:start]
				post := fixer.code[start:]
				fixer.code = pre + "fun" + post
				fixer.appliedFix = true
				break
			}
		default:
			/*panic: Parsing failed:
			error: expected token ')'
				--> :213:59
				|
				213 |     access(all) fun forEachCatalogKey(_ function: ((String): Bool)) {
			|   */
			fmt.Println(fixer.path)
			fmt.Println(v.Error())
			panic(v)
		}

		if fixer.appliedFix {
			//no error - stub out functions
			return true, fixer.code, fixer.program
		}

	}
	return false, fixer.code, fixer.program
}
