'use babel';

import * as path from 'path';

const lint = require('../lib/main.js').provideLinter().lint;

const badFile = path.join(__dirname, 'fixtures', 'bad.html');
const goodFile = path.join(__dirname, 'fixtures', 'good.html');

describe('The Tidy provider for Linter', () => {
  beforeEach(() => {
    atom.workspace.destroyActivePaneItem();
    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('linter-tidy'),
        atom.packages.activatePackage('language-html'),
      ]).then(() =>
        atom.workspace.open(goodFile)
      )
    );
  });

  describe('checks a file with issues and', () => {
    let editor = null;
    beforeEach(() => {
      waitsForPromise(() =>
        atom.workspace.open(badFile).then((openEditor) => {
          editor = openEditor;
        })
      );
    });

    it('finds at least one message', () => {
      waitsForPromise(() =>
        lint(editor).then(messages =>
          expect(messages.length).toBeGreaterThan(0)
        )
      );
    });

    it('verifies the first message', () => {
      const messageText = '<img> lacks "alt" attribute';
      waitsForPromise(() =>
        lint(editor).then((messages) => {
          expect(messages[0].type).toBe('Warning');
          expect(messages[0].html).not.toBeDefined();
          expect(messages[0].text).toBe(messageText);
          expect(messages[0].filePath).toBe(badFile);
          expect(messages[0].range).toEqual([[6, 0], [6, 4]]);
        })
      );
    });
  });

  it('finds nothing wrong with a valid file', () => {
    waitsForPromise(() =>
      atom.workspace.open(goodFile).then(editor =>
        lint(editor).then(messages =>
          expect(messages.length).toBe(0)
        )
      )
    );
  });

  it('finds errors on the fly', () => {
    waitsForPromise(() =>
      atom.workspace.open(goodFile).then((editor) => {
        editor.moveToBottom();
        editor.insertText('\n<h2>This should not be outside the body!</h2>\n');
        return lint(editor);
      }).then(messages =>
        expect(messages.length).toBeGreaterThan(0)
      )
    );
  });
});
