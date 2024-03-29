package main

import (
	"fmt"
	"github.com/bluesign/cadenceUpgrader/format"
	"github.com/bluesign/cadenceUpgrader/tools"
	"os"
	"strings"
)

func main() {

	if len(os.Args) < 2 {
		fmt.Println("Missing parameter, provide file name!")
		return
	}
	data_raw, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Println("Can't read file:", os.Args[1])
		panic(err)
	}

	code := string(data_raw)
	var fixed bool = false

	for {
		parserFixer := tools.NewParseFixer(code)
		fixed, code, _ = parserFixer.ParseAndFix()
		if fixed {
			print("!!! parser fix")
			continue
		}
		break
	}

	if err != nil {
		fmt.Println(err)
		panic("can't fix parsing errors, aborting.")
	}

	astFixer := tools.NewAstFixer(code)

	for {
		fixed, code = astFixer.WalkAndFix()
		if fixed {
			continue
		}

		//checker
		fixed, code = astFixer.CheckAndFix()
		if fixed {
			continue
		}

		break

	}

	newFileNameFormatted := strings.Replace(os.Args[1], ".cdc", "_1_Formatted.cdc", 1)
	newFileName := strings.Replace(os.Args[1], ".cdc", "_1.cdc", 1)

	var output = format.PrettyCode(string(code), 100, true)
	os.Create(newFileName)
	os.WriteFile(newFileName, []byte(code), 0644)
	os.Create(newFileNameFormatted)
	os.WriteFile(newFileNameFormatted, []byte(output), 0644)

}
