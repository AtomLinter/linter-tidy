module.exports =
  config:
    tidyExecutablePath:
      default: ''
      title: 'Tidy Executable Path'
      type: 'string'

  activate: ->
    console.log 'activate linter-tidy'
