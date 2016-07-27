'use babel';

import * as path from 'path';

const lint = require(path.join('..', 'lib', 'main.coffee')).provideLinter().lint;

// TODO: Implement variables and functions related to the main linter package.
//       When done, create a test that fails if the package is not available.
/**
 * Whether or not the main linter package functions are available.
 */
const linterAvailable = false;

/**
 * Invokes the linter package lint function on an editor.
 *
 * @param TextEditor editor The editor to invoke the lint function on.
 * @return Promise A promise that will return an array of
 *                 linter messages generated.
 */
const globalLint = () => new Promise((resolve, reject) => {
  reject('globalLint not implemented.');
});

const badFile = path.join(__dirname, 'fixtures', 'bad.html');
const goodFile = path.join(__dirname, 'fixtures', 'good.html');
const badHandlebarsFile = path.join(__dirname, 'fixtures', 'bad.hbs');

describe('The Tidy provider for Linter', () => {
  beforeEach(() => {
    atom.workspace.destroyActivePaneItem();
    waitsForPromise(() => {
      atom.packages.activatePackage('linter-tidy');
      return atom.packages.activatePackage('language-html').then(() =>
        atom.workspace.open(path.join(__dirname, 'fixtures', 'good.html'))
      );
    });
  });

  describe('checks a file with issues and', () => {
    let editor = null;
    beforeEach(() => {
      waitsForPromise(() =>
        atom.workspace.open(badFile).then(openEditor => {
          editor = openEditor;
        })
      );
    });

    it('finds at least one message', () => {
      waitsForPromise(() =>
        lint(editor).then(messages => {
          expect(messages.length).toBeGreaterThan(0);
        })
      );
    });

    it('verifies the first message', () => {
      waitsForPromise(() => {
        const messageText = '<img> lacks "alt" attribute';
        return lint(editor).then(messages => {
          expect(messages[0].type).toBe('Warning');
          expect(messages[0].html).not.toBeDefined();
          expect(messages[0].text).toBe(messageText);
          expect(messages[0].filePath).toBe(badFile);
          expect(messages[0].range).toEqual([[6, 0], [6, 4]]);
        });
      });
    });
  });

  it('finds nothing wrong with a valid file', () => {
    waitsForPromise(() =>
      atom.workspace.open(goodFile).then(editor =>
        lint(editor).then(messages => {
          expect(messages.length).toBe(0);
        })
      )
    );
  });

  it('finds errors on the fly', () => {
    waitsForPromise(() =>
      atom.workspace.open(goodFile).then(editor => {
        editor.moveToBottom();
        editor.insertText('\n<h2>This should not be outside the body!</h2>\n');
        return lint(editor);
      }).then(messages => {
        expect(messages.length).toBeGreaterThan(0);
      })
    );
  });

  describe('lints grammar scopes specified by the user and', () => {
    const itIfLinterAvailable = linterAvailable ? it : xit;

    itIfLinterAvailable('finds errors in included scopes', () => {
      expect(atom.config.set('linter-tidy.customGrammarScopes', [
        'text.html.mustache',
      ])).toBe(true);
      waitsForPromise(() =>
        atom.workspace.open(badHandlebarsFile).then(editor =>
          globalLint(editor)
        ).then(messages => {
          expect(messages.length).toBeGreaterThan(0);
        })
      );
    });

    itIfLinterAvailable('ignores errors in excluded scopes', () => {
      expect(atom.config.set('linter-tidy.customGrammarScopes', [])).toBe(true);
      waitsForPromise(() =>
        atom.workspace.open(badHandlebarsFile).then(editor =>
          globalLint(editor)
        ).then(messages => {
          expect(messages.length).toBe(0);
        })
      );
    });
  });
});
