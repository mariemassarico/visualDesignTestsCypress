# visualDesignTestsCypress
Project for visual tests

## Install Cypress

It's time for install Cypress and image-diff-js

### Usage

1. Download the `cypressInstall.sh` file in your root directory where the project will running;
2. Use a package for read shell script (in Visual Studio Code) or open the wsl;
3. Run
   ```
   ./cypressInstall.sh 1name-of-your-project 2your-name 3version-cypress(optional)
   ```
4. Enter in your directory;
5. Run the test example or adjust yours tests for running;
6. After run the tests, use the command for generate the report for image differences:
   ```
   npx cypress-image-diff-html-report generate
   ```
7. For visualization the report in html, use this command:
   ```
   npx cypress-image-diff-html-report start
   ```
