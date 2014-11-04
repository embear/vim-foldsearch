# Vim-Foldsearch

  - Bitbucket: https://bitbucket.org/embear/foldsearch
  - GitHub: https://github.com/embear/vim-foldsearch
  - VIM: http://www.vim.org/scripts/script.php?script_id=2302

## Credits

  - Karl Mowatt-Wilson for bug reports
  - John Appleseed for patches

## Description

This plugin provides commands that fold away lines that don't match a specific
search pattern. This pattern can be the word under the cursor, the last search
pattern, a regular expression or spelling errors. There are also commands to
change the context of the shown lines.

## Contribute

To contact the author (Markus Braun), please email: markus.braun@krawel.de

If you think this plugin could be improved, fork on Bitbucket or GitHub and
send a pull request or just tell me your ideas.

Bitbucket: https://bitbucket.org/embear/foldsearch
GitHub: https://github.com/embear/vim-foldsearch

## Documentation

See `doc/foldsearch.txt` for details

## Changelog

v1.1.0 : XXXX-YY-ZZ
  - use vim autoload feature to load functions on demand
  - better save/restore of modified options

v1.0.1 : 2013-03-20
  - added |g:foldsearch_disable_mappings| config variable

v1.0.0 : 2012-10-10
  - handle multiline regular expressions correctly

v2213 : 2008-07-26
  - fixed a bug in context handling

v2209 : 2008-07-17
  - initial version
