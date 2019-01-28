'use babel';

// eslint-disable-next-line import/no-extraneous-dependencies, import/extensions
import { CompositeDisposable } from 'atom';
import * as helpers from 'atom-linter';
import { dirname } from 'path';

// Local variables
const VALID_SEVERITY = new Set(['error', 'warning', 'info']);
const regex = /line (\d+) column (\d+) - (Warning|Error): (.+)/g;
const defaultExecutableArguments = [
  '-language', 'en',
  '-quiet',
  '-errors',
  '--tab-size', '1',
];
// Settings
const grammarScopes = [];
let executablePath;
let configExecutableArguments;

const getSeverity = (givenSeverity) => {
  const severity = givenSeverity.toLowerCase();
  return VALID_SEVERITY.has(severity) ? severity : 'warning';
};

export default {
  activate() {
    require('atom-package-deps').install('linter-tidy');

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.config.observe('linter-tidy.executablePath', (value) => {
        executablePath = value;
      }),
      atom.config.observe('linter-tidy.executableArguments', (value) => {
        configExecutableArguments = value;
      }),
      atom.config.observe('linter-tidy.grammarScopes', (configScopes) => {
        grammarScopes.splice(0, grammarScopes.length);
        grammarScopes.push(...configScopes);
      }),
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
      lintsOnChange: true,
      lint: async (textEditor) => {
        const filePath = textEditor.getPath();
        const fileText = textEditor.getText();

        const parameters = defaultExecutableArguments.concat(configExecutableArguments);

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
            severity: getSeverity(match[3]),
            excerpt: match[4],
            location: {
              file: filePath,
              position: helpers.generateRange(textEditor, line, col),
            },
          });
          match = regex.exec(output);
        }
        return messages;
      },
    };
  },
};
