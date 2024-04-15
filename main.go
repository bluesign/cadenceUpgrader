package main

import (
	"fmt"
	"github.com/bluesign/cadenceUpgrader/fixer"
	"os"
	"path"
	"path/filepath"
	"strings"
)

func main() {

	filepath.Walk("./contracts",
		func(spath string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}

			if strings.HasSuffix(spath, ".cdc") {

				data_raw, _ := os.ReadFile(spath)
				code := string(data_raw)

				newPath := strings.Replace(spath, "contracts/", "contractsV1/", 1)

				identifier := path.Base(newPath)
				libPath := fmt.Sprintf("./standardsV1/%s", identifier)
				_, err := os.ReadFile(libPath)
				if err != nil {
					_, err = os.ReadFile(newPath)
					if err != nil {
						fixer.FixFile(spath, newPath, code)
					}
				}

			}

			return nil
		})

}
