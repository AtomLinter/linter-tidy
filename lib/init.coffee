module.exports =
  config:
    tidyExecutablePath:
      default: null
      title: 'Tidy Executable Path'
      type: 'string'

  activate: ->
    console.log 'activate linter-tidy'
