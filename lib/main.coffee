{CompositeDisposable} = require('atom')

module.exports =
  config:
    executablePath:
      default: 'tidy'
      title: 'Full path to the `tidy` executable'
      type: 'string'

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-tidy.executablePath',
      (executablePath) =>
        @executablePath = executablePath

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    helpers = require('atom-linter')
    regex = /line (\d+) column (\d+) - (Warning|Error): (.+)/g
    provider =
      grammarScopes: ['text.html.basic']
      name: 'tidy'
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        fileText = textEditor.getText()
        return helpers.exec(
          @executablePath,
          ['-quiet', '-utf8', '-errors', filePath],
          {stream: 'stderr', stdin: fileText}
        ).then (output) ->
          messages = []
          match = regex.exec(output)
          while match != null
            line = match[1] - 1
            col = match[2] - 1
            range = helpers.rangeFromLineNumber(textEditor, line, col)
            messages.push({
              type: match[3],
              text: match[4],
              filePath,
              range
            })
            match = regex.exec(output)
          return messages
