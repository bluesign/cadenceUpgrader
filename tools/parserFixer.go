package tools

import (
	"fmt"
	"github.com/onflow/cadence/runtime/ast"
	"github.com/onflow/cadence/runtime/parser"
	"strings"
)

type ParseFixer struct {
	appliedFix   bool
	program      *ast.Program
	code         string
	replacements map[string]string
}

func NewParseFixer(code string) *ParseFixer {
	return &ParseFixer{
		appliedFix: false,
		program:    nil,
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
			fmt.Println("Applying suggestion: ", v.SuggestedFix)
			fixer.ReplaceElement(v, v.SuggestedFix)

		case *parser.CustomDestructorError:
			fmt.Println("Renaming old destructor")
			fixer.ReplaceElement(v, "access(self) fun LEGACY_d")

		case *parser.RestrictedTypeError:
			fmt.Println("Removing type restriction")
			pre := fixer.code[:v.StartPos.Offset-1]
			post := fixer.code[v.EndPos.Offset:]
			post = post[strings.Index(post, "}")+1:]
			fixer.code = pre + post
			fixer.appliedFix = true

		case *parser.SyntaxError:
			if strings.Contains(v.Message, "got keyword") {
				pre := fixer.code[:v.StartPosition().Offset]
				post := fixer.code[v.EndPosition(nil).Offset+1:]
				fixer.code = pre + "_" + post
				fixer.appliedFix = true
			}

			if strings.Contains(v.Message, "expected authorization (entitlement list)") {
				pre := fixer.code[:v.StartPosition().Offset-5]
				post := fixer.code[v.EndPosition(nil).Offset:]
				fixer.code = pre + post
				fixer.appliedFix = true
			}
		default:
			panic(v)
		}

		if fixer.appliedFix {
			return true, fixer.code, fixer.program
		}

	}
	return false, fixer.code, fixer.program
}
