{CompositeDisposable} = require('atom')

module.exports =
  config:
    executablePath:
      default: 'tidy'
      title: 'Full path to the `tidy` executable'
      type: 'string'
    tidyConfigName:
      default: '.tidyconfig.cfg'
      title: 'Name for `tidyconfig` file ' +
      '(located at the root of project directories, or with files in a folder)'
      description: 'See the ' +
        '[tidy-html5 API reference]' +
        '(http://api.html-tidy.org/tidy/quickref_5.2.0.html#doctype) '+
        'for configuration options'
      type: 'string'

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-tidy.executablePath',
      (executablePath) =>
        @executablePath = executablePath
    @subscriptions.add atom.config.observe 'linter-tidy.tidyConfigName',
      (tidyConfigName) =>
        @tidyConfigName = tidyConfigName

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    helpers = require('atom-linter')
    path = require('path')
    fs = require('fs')
    regex = /line (\d+) column (\d+) - (Warning|Error): (.+)/g
    provider =
      grammarScopes: ['text.html.basic']
      name: 'tidy'
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        fileText = textEditor.getText()
        fileDir = textEditor.getDirectoryPath()
        projectPaths = textEditor.project.getPaths() if textEditor.project
        try
          fileConfigFile = path.join fileDir, @tidyConfigName
          if fs.statSync fileConfigFile
            configFile = fileConfigFile
            if atom.devMode
              console.debug 'Using tidy config file at: ' + fileConfigFile
        catch err
          if atom.devMode
            console.debug 'No tidy config file found at ' +
            fileConfigFile + ', trying project root'
          if projectPaths and !configFile
            for projectPath of projectPaths
              thisPath = projectPaths[projectPath]
              if !configFile
                try
                  projectConfigFile = path.join thisPath, @tidyConfigName
                  if fs.statSync projectConfigFile
                    configFile = projectConfigFile
                    if atom.devMode
                      console.debug 'Using tidy config file at: ' +
                      projectConfigFile
                catch err
                  if parseInt projectPath, 10 == projectPaths.length - 1
                    msg = ', tidy defaults will be used'
                  else
                    msg = ', trying next project folder'
                  if atom.devMode
                    console.debug 'No tidy config file found at ' +
                    projectConfigFile + msg
        options = ['-quiet', '-utf8', '-errors']
        if configFile
          options.unshift '-config', configFile
        return helpers.exec(
          @executablePath,
          options,
          {stream: 'stderr', stdin: fileText, allowEmptyStderr: true}
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
