'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable } from 'atom';
import * as helpers from 'atom-linter';
import { dirname } from 'path';

// Local variables
const regex = /line (\d+) column (\d+) - (Warning|Error): (.+)/g;
// Settings
const grammarScopes = [];
let executablePath;

export default {
  activate() {
    require('atom-package-deps').install('linter-tidy');

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.config.observe('linter-tidy.executablePath', (value) => {
        executablePath = value;
      })
    );

    // Add a listener to update the list of grammar scopes linted when the
    // config value changes.
    this.subscriptions.add(
      atom.config.observe('linter-tidy.grammarScopes', (configScopes) => {
        grammarScopes.splice(0, grammarScopes.length);
        grammarScopes.push(...configScopes);
      })
    );
  },

  deactivate() {
    this.subscriptions.dispose();
  },

  provideLinter() {
    return {
      grammarScopes,
      name: 'tidy',
      scope: 'file',
      lintOnFly: true,
      lint: async (textEditor) => {
        const filePath = textEditor.getPath();
        const fileText = textEditor.getText();

        const parameters = ['-quiet', '-utf8', '-errors'];

        const [projectPath] = atom.project.relativizePath(filePath);
        const execOptions = {
          stream: 'stderr',
          stdin: fileText,
          cwd: projectPath !== null ? projectPath : dirname(filePath),
          allowEmptyStderr: true,
        };

        const output = await helpers.exec(executablePath, parameters, execOptions);

        if (textEditor.getText() !== fileText) {
          // Editor contents have changed, don't update the messages
          return null;
        }

        const messages = [];
        let match = regex.exec(output);
        while (match !== null) {
          const line = Number.parseInt(match[1], 10) - 1;
          const col = Number.parseInt(match[2], 10) - 1;
          messages.push({
            type: match[3],
            text: match[4],
            filePath,
            range: helpers.rangeFromLineNumber(textEditor, line, col),
          });
          match = regex.exec(output);
        }
        return messages;
      },
    };
  },
};
