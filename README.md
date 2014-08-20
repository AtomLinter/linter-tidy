# linter-tidy

This package will lint your `.html` opened files in Atom through [tidy](http://tidy.sourceforge.net/).

## Installation

* Install [tidy](http://tidy.sourceforge.net/)
* `$ apm install language-html` (if you don't have [language-html](https://github.com/atom/language-html) installed)
* `$ apm install linter` (if you don't have [linter](https://github.com/AtomLinter/Linter) installed)
* `$ apm install linter-tidy`

## Settings
You can configure linter-tidy by editing ~/.atom/config.cson (choose Open Your Config in Atom menu):
```
'linter-tidy':
  'tidyExecutablePath': null # tidy path. run 'which tidy' to find the path
```

## Donation
[![Share the love!](https://chewbacco-stuff.s3.amazonaws.com/donate.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KXUYS4ARNHCN8)
