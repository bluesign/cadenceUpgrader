package fixer

import (
	"slices"
	"strings"

	"github.com/onflow/cadence/runtime/parser"
	"github.com/onflow/cadence/runtime/parser/lexer"
	"github.com/openconfig/goyang/pkg/indent"
	"github.com/turbolent/prettier"
)

func extractTokenText(text string, token lexer.Token) string {
	return text[token.StartPos.Offset : token.EndPos.Offset+1]
}

func pretty(code string, maxLineWidth int) string {
	program, err := parser.ParseProgram(nil, []byte(code), parser.Config{})
	if err != nil {
		return err.Error()
	}

	var b strings.Builder
	prettier.Prettier(&b, program.Doc(), maxLineWidth, "    ")
	return b.String()
}

func PrettyCode(existingCode string, maxLineLength int, tabs bool) string {
	existingCodeLines := strings.Split(existingCode, "\n")
	oldTokens := lexer.Lex([]byte(existingCode), nil)

	prettyCode := pretty(existingCode, maxLineLength)
	if strings.HasPrefix(prettyCode, "Parsing failed:") {
		return prettyCode
	}
	newTokens := lexer.Lex([]byte(prettyCode), nil)

	oldToken := lexer.Token{Type: lexer.TokenSpace}
	newToken := lexer.Token{Type: lexer.TokenSpace}

	ignoredTokenTypes := []lexer.TokenType{
		lexer.TokenParenClose,
		lexer.TokenParenOpen,
		lexer.TokenBracketOpen,
		lexer.TokenBracketClose,
	}

	result := strings.Builder{}
	spaces := strings.Builder{}
	comment := strings.Builder{}

	for {

		if !newToken.Is(lexer.TokenEOF) {
			newToken = newTokens.Next()
		}

		if newToken.Is(lexer.TokenSpace) {
			spaces.WriteString(extractTokenText(prettyCode, newToken))
			continue
		}

		//temporary fix for pretty producing extra {} for interface members without default impl.
		if newToken.Is(lexer.TokenBraceOpen) {
			cursor := newTokens.Cursor()
			if newTokens.Next().Type == lexer.TokenBraceClose {
				result.WriteString("{}")
				continue
			} else {
				result.WriteString("{")
				newTokens.Revert(cursor)
				continue
			}

		}

		if slices.Contains(ignoredTokenTypes, newToken.Type) {
			result.WriteString(spaces.String())
			result.WriteString(extractTokenText(prettyCode, newToken))
			spaces.Reset()
			continue
		}

		if !oldToken.Is(lexer.TokenEOF) {
			for {
				oldToken = oldTokens.Next()

				//check only comments
				if oldToken.Is(lexer.TokenLineComment) || oldToken.Is(lexer.TokenBlockCommentContent) {

					switch oldToken.Type {
					case lexer.TokenLineComment:
						isTrailing := false

						//check trailing
						oldLine := existingCodeLines[oldToken.StartPosition().Line-1][:oldToken.StartPosition().Column]
						oldLine = strings.Trim(oldLine, " \t")
						if len(oldLine) > 0 {
							isTrailing = true
						}

						//check previous line empty
						if !isTrailing && oldToken.StartPosition().Line > 1 {
							if len(strings.Trim(existingCodeLines[oldToken.StartPosition().Line-2], " \t")) == 0 {
								//leading comment
								if len(oldLine) == 0 && !strings.HasSuffix(strings.Replace(spaces.String(), " ", "", -1), "\n\n") {
									comment.WriteString("\n")
								}
							}
						}

						//add comment
						comment.WriteString(extractTokenText(existingCode, oldToken))

						//check next line empty
						if false && !isTrailing && oldToken.StartPosition().Line < len(existingCodeLines) {
							if len(strings.Trim(existingCodeLines[oldToken.StartPosition().Line], " \t")) == 0 {
								//leading comment
								if len(oldLine) == 0 {
									comment.WriteString("\n")
								}
							}
						}

						//trailing comment
						if isTrailing {
							//space before trailing comment
							result.WriteString(" ")
							result.WriteString(comment.String())
							comment.Reset()
							comment.WriteString("\n")

						} else {
							comment.WriteString("\n")
						}

					case lexer.TokenBlockCommentContent:
						commentString := extractTokenText(existingCode, oldToken)
						comment.WriteString("/*")
						comment.WriteString(commentString)
						comment.WriteString("*/")

						if oldToken.StartPos.Line < oldToken.EndPos.Line {
							//multiline block comment
							comment.WriteString("\n\n")
						} else {
							comment.WriteString("\n")

						}
					}

				}

				if oldToken.Type == newToken.Type || oldToken.Is(lexer.TokenEOF) {
					break
				}
			}
		}

		if oldToken.Is(lexer.TokenEOF) && newToken.Is(lexer.TokenEOF) {
			//add remaining comments and finish
			result.WriteString(comment.String())
			break
		}

		//add spaces without existing indent in case we put comment
		spacesString := spaces.String()
		existingIndent := len(spacesString) - (strings.LastIndex(spacesString, "\n") + 1)
		result.WriteString(strings.TrimRight(spacesString, " "))
		spaces.Reset()

		if comment.Len() > 0 {
			//add existing comment (leading), pad to next element
			padding := strings.Repeat(" ", newToken.StartPosition().Column)
			result.WriteString(indent.String(padding, comment.String()))
			result.WriteString(padding)
			comment.Reset()
		} else {
			result.WriteString(strings.Repeat(" ", existingIndent))
		}

		//add prettified code
		result.WriteString(extractTokenText(prettyCode, newToken))

	}

	if !tabs {
		return result.String()
	}

	tabbedResult := &strings.Builder{}
	for _, line := range strings.Split(result.String(), "\n") {
		newline := line
		for {
			if strings.Index(strings.TrimLeft(newline, "\t"), strings.Repeat(" ", 4)) == -1 {
				break
			}
			newline = strings.Replace(newline, strings.Repeat(" ", 4), "\t", 1)
		}
		tabbedResult.WriteString(newline)
		tabbedResult.WriteString("\n")
	}

	return tabbedResult.String()
}
