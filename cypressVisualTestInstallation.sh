#!/usr/bin/env bash

# Establish a project directory and navigate to it.
mkdir $1
cd $1

# Initialize git and .gitignore
git init
touch .gitignore
echo '{
    .env
    cypress.env.json
    node_modules/
    cypress/downloads/
    cypress/screenshots/
}' >.gitignore

# Initialize NPM
npm init -y

# Changes at package.json

# create the author variable
author_name="$2"

# changes in package.json without jq
sed -i 's#"description": ""#"description": "Experiment with image-diff and cypress for visual tests"#' package.json
sed -i '/"test": "echo /d' package.json
sed -i 's#"scripts": {#"scripts": {\
    "cypress:open": "npx cypress open ./node_modules/.bin/",\
    "cypress:run": "npx cypress run ./node_modules/.bin/",\
    "cypress:runSpecAndTags": "npx cypress run --spec caminhoDoArquivo --env grepTags=@visualTests",\
    "cypress:runTags": "npx cypress run --env grepTags=@visualTests",\
    "vrtGenerateReport": "cypress-image-diff-html-report generate",\
    "vrtStartReport": "cypress-image-diff-html-report start"#' package.json
sed -i 's#"keywords": \[\]#"keywords": [\
    "visual test",\
    "cypress-image-diff-js",\
    "cypress-image-diff-html-report",\
    "cypress.io"\
]#' package.json
sed -i 's/"author": ""/"author": "'"$author_name"'"/' package.json
sed -i 's/"license": "ISC"/"license": "MIT"/' package.json

# Install Cypress (if a version is specified, it will be installed; otherwise, the latest version will be installed).
if [ "$3" ]; then
  npm i cypress@"$3" -D
else
  npm i cypress -D
fi

# Create the test directories
mkdir cypress
mkdir cypress/e2e cypress/fixtures cypress/screenshots cypress/support
mkdir cypress/e2e/visualTests

# Install the cypress-image-diff-js and others packages
npm install cypress-image-diff-js --save-dev
npm install cypress-image-diff-html-report --save-dev
npm install cypress-real-events --save-dev
npm install @cypress/grep --save-dev

# create the cypress.env.json
touch cypress.env.example.json
echo '{
    "email": "{{CYPRESS_USER}}",
    "senha": "{{CYPRESS_PASS}}",
    "email2": "{{CYPRESS_USER2}}",
    "senha2": "{{CYPRESS_PASS2}}"
}' >cypress.env.example.json

cp cypress.env.example.json cypress.env.json

# Changes in Cypress configuration for running
echo 'const { defineConfig } = require("cypress");
const getCompareSnapshotsPlugin = require("cypress-image-diff-js/plugin");

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      return getCompareSnapshotsPlugin(on, config);
    },
    baseUrl: "https://front.serverest.dev",
    chromeWebSecurity: false,
    pageLoadTimeout: 30000,
    requestTimeout: 30000,
    defaultCommandTimeout: 30000,
    // retries: 1, //argumento para definir o número de tentativas se o teste não passar
    viewportWidth: 1920,
    viewportHeight: 1080,
    testIsolation: false,
    watchForFileChanges: false,
  },
});' >cypress.config.js

# create the directories for running the image-diff
mkdir cypress-image-diff-html-report cypress-image-diff-screenshots
mkdir cypress-image-diff-screenshots/baseline cypress-image-diff-screenshots/comparison cypress-image-diff-screenshots/diff

# create the configuration for image-diff config and html report

echo 'const config = {
  FAILURE_THRESHOLD: 0.05 /*passa em todos os testes, desde que não seja superior a 10%*/,
  COMPARISON_OPTIONS: {
    threshold: 0.04 /* é o limite de falha para cada comparação de pixels*/,
  },

  CYPRESS_SCREENSHOT_OPTIONS: {
    disableTimersAndAnimations: false,
    screenshotOnRunFailure: false,
  },
};
module.exports = config;' >cypress-image-diff.config.js

echo 'const config = {
  reportJsonDir: "visual_tests_report",
  reportJsonFilePath: "visual_tests_report",
  outputDir: "visual_tests_report",
  baseDir: "./reports",
  inlineAssets: false,
  autoOpen: false,
  serverPort: 6868,
};
module.exports = config;' >cypress-image-html-report.config.js

# create commands and add the plugin in this project
cd cypress/support

echo "Cypress.Commands.add('loginKC', (yourURL,email, senha) => {
    cy.session([yourURL, email, senha], () => {
        cy.visit(yourURL)
        cy.get('.redirect-button').click()
        cy.get('#username').type(email)
        cy.get('#password').type(senha, {log: false})
        cy.get('#kc-login').click()
    })
})

Cypress.Commands.add('login', (email, password) => {
  cy.get($([data-testid='email'])).type(email);
  cy.get($([data-testid='senha'])).type(password);
  cy.intercept({
    method: 'POST',
    url: 'https://serverest.dev/login',
  }).as('apiLogin');
  cy.get($([data-testid='entrar'])).click();
  cy.wait('@apiLogin').then((interception) => {
    expect(interception.response.statusCode).to.eq(200);
    expect(interception.response.body.message).to.equal(
      'Login realizado com sucesso'
    );
    expect(interception.response.body).to.have.all.keys(
      'authorization',
      'message'
    );
  });
});" >commands.js

echo '/// <reference types="cypress" />
import "./commands";

const compareSnapshotCommand = require("cypress-image-diff-js/command");
compareSnapshotCommand();

import "cypress-real-events";

const registerCypressGrep = require("@cypress/grep");
registerCypressGrep();' >e2e.js

# create the test for serverest plataform
cd ..
cd e2e/visualTests

echo 'describe("Visual Regression Testing", () => {
  beforeEach(() => {
    cy.visit("/login");
  });

  context("Validate login page state default", () => {
    it(
      "Should visual default in the web login page Funcional",
      { tags: "@FuncionalvisualTests" },
      () => {
        // sem VRT
        cy.get(".form").should("exist").and("be.visible");

        cy.get(".imagem").should("exist").and("be.visible");

        cy.get(".font-robot")
          .should("exist")
          .and("be.visible")
          .and("have.text", "Login");

        cy.get(`[data-testid="email"]`)
          .should("exist")
          .and("be.visible")
          .and("be.enabled")
          .and("have.attr", "placeholder", "Digite seu email");

        cy.get(`[data-testid="senha"]`)
          .should("exist")
          .and("be.visible")
          .and("be.enabled")
          .and("have.attr", "placeholder", "Digite sua senha");

        cy.get(`[data-testid="entrar"]`)
          .should("exist")
          .and("be.visible")
          .and("be.enabled")
          .and("have.text", "Entrar");

        cy.get(".message")
          .should("exist")
          .and("be.visible")
          .and("not.be.enabled")
          .and("contain", "Não é cadastrado?");

        cy.get(`[data-testid="cadastrar"]`)
          .should("exist")
          .and("be.visible")
          .and("not.be.enabled")
          .and("have.text", "Cadastre-se");
      }
    );

    it("Should display all required components",
      { tags: "@visualTests" },
      () => {
        // assim no meu teste visual funcional só preciso validar se os componentes estão habilitadados para ação
        cy.get(`[data-testid="email"]`).and("be.enabled");
        cy.get(`[data-testid="senha"]`).and("be.enabled");
        cy.get(`[data-testid="entrar"]`).and("be.enabled");
      }
    );

    it(
      "Should visual default in the web login page",
      { tags: "@visualTests" },
      () => {
        cy.compareSnapshot("login-page-default-web");
      }
    );

    it(
      "Should visual default in the web login page",
      { tags: "@visualTests" },
      () => {
        // fazendo validação visual do modal usando uma imagem genérica
        cy.get(".form").compareSnapshot("modal-login-commom");
      }
    );

    it(
      "Should visual default in the mobile login page",
      { tags: "@visualTests" },
      () => {
        cy.viewport(360, 740);
        cy.compareSnapshot("login-page-default-mobile");
      }
    );
  });

  context.only("Validate invalid login page state default", () => {
    beforeEach(() => {
      // cy.visit("/login");
      cy.get(`[data-testid="email"]`).type("teste@email.com");
      cy.get(`[data-testid="senha"]`).type("Failll");
      cy.intercept({
        method: "POST",
        url: "https://serverest.dev/login",
      }).as("apiLogin");
      cy.get(`[data-testid="entrar"]`).click();
      cy.wait("@apiLogin").then((interception) => {
        expect(interception.response.statusCode).to.eq(401);
        expect(interception.response.body.message).to.equal(
          "Email e/ou senha inválidos"
        );
      });
    });

    it(
      "Should modal visual when invalid login",
      { tags: "@visualTests" },
      () => {
        // podemos validar toda localização, espaçamento
        //   cores e textos em apenas uma imagem
        cy.get(".form").compareSnapshot("form-invalid-login");
      }
    );

    it("Should modal visual login", { tags: "@visualTests" }, () => {
      // esse teste não faz sentido nesse context, é apenas pra mostrar o reaproveitamento da imagem
      // escodendo componente para validar um componente modal como um commom
      cy.get(".alert").invoke("css", "display", "none");
      cy.get(`[data-testid="email"]`).clear();
      cy.get(`[data-testid="senha"]`).clear();
      cy.get(".form").compareSnapshot("modal-login-commom");
    });

    it(
      "Should alert visual when invalid login",
      { tags: "@visualTests" },
      () => {
        cy.get(".form").compareSnapshot("alert-invalid-login");

        //garantindo validação da cor do componente de alerta
        cy.get(".alert")
          .should("have.css", "background-color")
          .and("eq", "rgb(243, 150, 154)");
      }
    );
    
    it("Should visual appearance when hovering over icon close", () => {
      // a API snapshot do cypress tem um comportamento, que quando é executado
      // ele retira a ação de mouse hover, impedindo a validação visual dessa ação
      cy.get(".close > span")
        .realHover()
        .should("have.css", "background-color")
        .and("eq", "rgba(0, 0, 0, 0)");
    });

    it(
      "Should visual when invalid login - Functional test",
      { tags: "@FuncionalvisualTests" },
      () => {
        //sem VRT
        cy.get(".form").should("exist").and("be.visible");

        cy.get(".imagem").should("exist").and("be.visible");

        cy.get(".font-robot")
          .should("exist")
          .and("be.visible")
          .and("have.text", "Login");

        cy.get(".alert")
          .should("exist")
          .and("be.visible")
          .and("have.text", "Email e/ou senha inválidos");

        cy.get(".close > span").should("exist").and("be.visible");

        cy.get(`[data-testid="email"]`)
          .should("exist")
          .and("be.visible")
          .and("be.enabled")
          .and("have.value", email);

        cy.get(`[data-testid="senha"]`)
          .should("exist")
          .and("be.visible")
          .and("be.enabled")
          .and("have.value", "Failll");

        cy.get(`[data-testid="entrar"]`)
          .should("exist")
          .and("be.visible")
          .and("be.enabled")
          .and("have.text", "Entrar");

        cy.get(".message")
          .should("exist")
          .and("be.visible")
          .and("not.be.enabled")
          .and("contain", "Não é cadastrado?");

        cy.get(`[data-testid="cadastrar"]`)
          .should("exist")
          .and("be.visible")
          .and("not.be.enabled")
          .and("have.text", "Cadastre-se");
      }
    );
  });
});' >vrtExample.cy.js
