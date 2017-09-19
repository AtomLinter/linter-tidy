'use babel';

// eslint-disable-next-line no-unused-vars
import { it, fit, wait, beforeEach, afterEach } from 'jasmine-fix';
import * as path from 'path';

const { lint } = require('../lib/main.js').provideLinter();

const badFile = path.join(__dirname, 'fixtures', 'bad.html');
const badTabFile = path.join(__dirname, 'fixtures', 'bad_tab.html');
const goodFile = path.join(__dirname, 'fixtures', 'good.html');

describe('The Tidy provider for Linter', () => {
  beforeEach(async () => {
    atom.workspace.destroyActivePaneItem();
    await atom.packages.activatePackage('linter-tidy');
    await atom.packages.activatePackage('language-html');
    await atom.workspace.open(goodFile);
  });

  it('checks a file with issues', async () => {
    const editor = await atom.workspace.open(badFile);
    const messages = await lint(editor);
    const messageText = '<img> lacks "alt" attribute';

    expect(messages.length).toBe(1);
    expect(messages[0].type).toBe('Warning');
    expect(messages[0].html).not.toBeDefined();
    expect(messages[0].text).toBe(messageText);
    expect(messages[0].filePath).toBe(badFile);
    expect(messages[0].range).toEqual([[6, 0], [6, 4]]);
  });

  it('finds nothing wrong with a valid file', async () => {
    const editor = await atom.workspace.open(goodFile);
    const messages = await lint(editor);

    expect(messages.length).toBe(0);
  });

  it('handles files indented with tabs', async () => {
    const editor = await atom.workspace.open(badTabFile);
    const messages = await lint(editor);

    expect(messages.length).toBeGreaterThan(0);
  });

  it('finds errors on the fly', async () => {
    const editor = await atom.workspace.open(goodFile);
    editor.moveToBottom();
    editor.insertText('\n<h2>This should not be outside the body!</h2>\n');
    const messages = await lint(editor);

    expect(messages.length).toBeGreaterThan(0);
  });

  describe('allows for custom executable arguments and', () => {
    it('ignores errors that a user has chosen to ignore', async () => {
      expect(atom.config.set('linter-tidy.executableArguments', [
        '-utf8',
        '--show-warnings',
        'false',
      ])).toBe(true);
      const editor = await atom.workspace.open(badFile);
      const messages = await lint(editor);

      expect(messages.length).toBe(0);
    });

    it('works as expected with an empty array of custom arguments', async () => {
      expect(atom.config.set('linter-tidy.executableArguments', [])).toBe(true);
      const goodEditor = await atom.workspace.open(goodFile);
      const goodMessages = await lint(goodEditor);
      expect(goodMessages.length).toBe(0);

      const badEditor = await atom.workspace.open(badFile);
      const badMessages = await lint(badEditor);
      expect(badMessages.length).toBeGreaterThan(0);
    });
  });
});
