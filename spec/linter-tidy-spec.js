'use babel';

import * as path from 'path';

describe('The Tidy provider for Linter', () => {
  const lint = require(path.join('..', 'lib', 'main.coffee')).provideLinter().lint;

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
    const badFile = path.join(__dirname, 'fixtures', 'bad.html');
    beforeEach(() => {
      waitsForPromise(() => {
        return atom.workspace.open(badFile).then(openEditor => {
          editor = openEditor;
        });
      });
    });

    it('finds at least one message', () => {
      waitsForPromise(() => {
        return lint(editor).then(messages => {
          expect(messages.length).toBeGreaterThan(0);
        });
      });
    });

    it('verifies the first message', () => {
      waitsForPromise(() => {
        const messageText = '<img> lacks "alt" attribute';
        return lint(editor).then(messages => {
          expect(messages[0].type).toBeDefined();
          expect(messages[0].type).toEqual('Warning');
          expect(messages[0].text).toBeDefined();
          expect(messages[0].text).toEqual(messageText);
          expect(messages[0].filePath).toBeDefined();
          expect(messages[0].filePath).toMatch(/.+bad\.html$/);
          expect(messages[0].range).toBeDefined();
          expect(messages[0].range.length).toBeDefined();
          expect(messages[0].range.length).toEqual(2);
          expect(messages[0].range).toEqual([[6, 0], [6, 21]]);
        });
      });
    });
  });

  it('finds nothing wrong with a valid file', () => {
    waitsForPromise(() => {
      const goodFile = path.join(__dirname, 'fixtures', 'good.html');
      return atom.workspace.open(goodFile).then(editor => {
        return lint(editor).then(messages => {
          expect(messages.length).toEqual(0);
        });
      });
    });
  });
});
