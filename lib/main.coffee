{CompositeDisposable} = require('atom')

# The grammar scopes checked by this linter.
grammarScopes = []

module.exports =
  config:
    executablePath:
      default: 'tidy'
      title: 'Full path to the `tidy` executable'
      type: 'string'
    grammarScopes:
      default: [
        'text.html.basic'
      ]
      title: 'Grammar Scopes'
      description: 'A list of grammar scopes to lint with Tidy.<br/><br/>
        By default, this package only lints HTML scopes known to work cleanly
        with Tidy. If you know of any HTML variants that Tidy works with without
        producing spurious errors, please
        [let us know](https://github.com/AtomLinter/linter-tidy/issues)
        so that we may improve the default list.<br/><br/>
        To find the grammar scopes used by a file, use the `Editor: Log Cursor
        Scope` command.'
      type: 'array'
      items:
        type: 'string'

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-tidy.executablePath',
      (executablePath) =>
        @executablePath = executablePath

    # Add a listener to update the list of grammar scopes linted when the
    # config value changes.
    @subscriptions.add atom.config.observe 'linter-tidy.grammarScopes',
      (configScopes) ->
        grammarScopes.splice(0, grammarScopes.length)
        grammarScopes.push(configScopes...)

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    helpers = require('atom-linter')
    path = require('path')
    regex = /line (\d+) column (\d+) - (Warning|Error): (.+)/g
    provider =
      grammarScopes: grammarScopes
      name: 'tidy'
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        fileText = textEditor.getText()
        [projectPath] = atom.project.relativizePath(filePath)
        cwd = if projectPath? then projectPath else path.dirname(filePath)
        return helpers.exec(
          @executablePath,
          ['-quiet', '-utf8', '-errors'],
          {stream: 'stderr', stdin: fileText, cwd, allowEmptyStderr: true}
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
