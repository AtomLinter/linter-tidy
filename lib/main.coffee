{CompositeDisposable} = require('atom')

module.exports =
  config:
    tidyExecutablePath:
      default: 'tidy'
      title: 'Tidy Executable Path'
      type: 'string'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-tidy.executablePath',
      (executablePath) =>
        @executablePath = executablePath
  deactivate: ->
    @subscriptions.dispose()
  provideLinter: ->
    helpers = require('atom-linter')
    regex = 'line (?<line>\\d+) column (?<col>\\d+) - ((?<error>Error)|(?<warning>Warning)): (?<message>.+)'
    provider =
      grammarScopes: ['text.html.basic']
      scope: 'file'
      lintOnFly: false # must be false for scope: 'project'
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        return helpers.exec(@executablePath, ['-quiet', '-utf8', filePath], {stream: 'stderr'})
        .then (contents) ->
          return helpers.parse(contents, regex)
