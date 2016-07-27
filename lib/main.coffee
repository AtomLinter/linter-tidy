{CompositeDisposable} = require('atom')

# The default grammar scopes checked by this linter.
defaultGrammarScopes = [
  'text.html.basic'
]

module.exports =
  config:
    executablePath:
      default: 'tidy'
      title: 'Full path to the `tidy` executable'
      type: 'string'
    customGrammarScopes:
      default: []
      title: 'Custom Grammar Scopes'
      description: 'A list of extra grammar scopes to lint with Tidy.<br/><br/>
        By default, this package only lints HTML scopes known to work cleanly
        with Tidy. If you know of any HTML variants that Tidy works with without
        producing spurious errors, please
        [let us know](https://github.com/AtomLinter/linter-tidy/issues)
        so that we may improve the default list.<br/><br/>
        The following grammar scopes are linted by default and do not need to
        be included below: ' + defaultGrammarScopes.join(', ')
      type: 'array'
      items:
        type: 'string'

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-tidy.executablePath',
      (executablePath) =>
        @executablePath = executablePath

    # Add a listener to reload this package if the custom grammar scopes setting
    # changes. Grammar scopes can only be set at load time.
    @subscriptions.add atom.config.observe 'linter-tidy.customGrammarScopes',
      () ->
        # Only reload the package if it is not already active.
        # Otherwise, Atom could get stuck in an infinite loop.
        if !atom.packages.isPackageActive('linter-tidy')
          return

        atom.packages.deactivatePackage('linter-tidy')
        atom.packages.activatePackage('linter-tidy')

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    helpers = require('atom-linter')
    path = require('path')
    regex = /line (\d+) column (\d+) - (Warning|Error): (.+)/g
    grammarScopes = defaultGrammarScopes.slice()

    # Add user-specified grammar scopes to the list of scopes to lint.
    customGrammarScopes = atom.config.get('linter-tidy.customGrammarScopes')
    for customGrammarScope in customGrammarScopes
      if customGrammarScope in grammarScopes
        continue
      grammarScopes.push customGrammarScope

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
