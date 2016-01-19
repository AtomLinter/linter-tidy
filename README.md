# linter-tidy

This package will lint your `.html` opened files in Atom through [tidy-html5](http://www.htacg.org/tidy-html5).

## Installation

*   Install [tidy-html5](http://www.htacg.org/tidy-html5)
*   `$ apm install linter-tidy`

## Settings

You can configure linter-tidy by editing ~/.atom/config.cson (choose Open Your
Config in Atom menu):

```coffeescript
'linter-tidy':
  'tidyExecutablePath': null # tidy path. run 'which tidy' to find the path
```
