linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

class LinterTidy extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ['text.html.basic']

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: 'tidy -quiet -utf8'

  executablePath: null

  linterName: 'tidy'

  errorStream: 'stderr'

  # A regex pattern used to extract information from the executable's output.
  regex: 'line (?<line>\\d+) column (?<col>\\d+) - ((?<error>Error)|(?<warning>Warning)): (?<message>.+)'

  constructor: (editor) ->
    super(editor)

    @executablePathListener = atom.config.observe 'linter-tidy.tidyExecutablePath', =>
      @executablePath = atom.config.get 'linter-tidy.tidyExecutablePath'

  destroy: ->
    @executablePathListener.dispose()

module.exports = LinterTidy
