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
    regex = 'line (?<line>\\d+) column (?<col>\\d+) - ((?<error>Error)|(?<warning>Warning)): (?<message>.+)'
    provider =
      grammarScopes: ['text.html.basic']
      name: 'tidy'
      scope: 'file'
      lintOnFly: false
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        return helpers.exec(@executablePath, ['-quiet', '-utf8', '-errors', filePath], {stream: 'stderr'})
        .then (contents) ->
          return helpers.parse(contents, regex).map((message) ->
            message.type = 'error'
          )
