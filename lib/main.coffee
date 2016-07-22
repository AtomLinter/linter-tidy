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
    _path = require('path')
    _interopRequireDefault = (obj) ->
      if obj and obj.__esModule then obj else default: obj
    _path2 = _interopRequireDefault(_path)

    regex = /line (\d+) column (\d+) - (Warning|Error): (.+)/g
    provider =
      grammarScopes: ['text.html.basic']
      name: 'tidy'
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        fileText = textEditor.getText()
        fileDir = _path2.default.dirname(filePath)

        configFile = helpers.findCached fileDir, ['.tidyrc', '.tidyconfig.cfg', '.tidyconfig.txt', 'tidyconfig.cfg', 'tidyconfig.txt']
        console.info configFile
        if configFile
          options = ['-config', configFile, '-quiet', '-utf8', '-errors']
        else
          options = ['-quiet', '-utf8', '-errors']
        # console.info options
        return helpers.exec(
          @executablePath,
          options,
          {stream: 'stderr', stdin: fileText, allowEmptyStderr: true}
        ).then (output) ->
          console.info(output)
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
