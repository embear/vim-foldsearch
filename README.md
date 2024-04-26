# Foldsearch

This plugin provides commands that fold away lines that don't match a specific
search pattern. This pattern can be the word under the cursor, the last search
pattern, a regular expression or spelling errors. There are also commands to
change the context of the shown lines.

The plugin can be found on [GitHub] and [VIM online].

## Commands

### The `:Fw` command

Show lines which contain the word under the cursor.

The optional *context* option consists of one or two numbers:

  - A 'unsigned' number defines the context before and after the pattern.
  - If a number has a '-' prefix, it defines only the context before the pattern.
  - If it has a '+' prefix, it defines only the context after a pattern.

Default *context* is current context.

### The `:Fs` command

Show lines which contain previous search pattern.

For a description of the optional *context* please see |:Fw|

Default *context* is current context.

### The `:Fp` command

Show the lines that contain the given regular expression.

Please see |regular-expression| for patterns that are accepted.

### The `:FS` command

Show the lines that contain spelling errors.

### The `:Ft` command

Toggle between foldsearch view and original view.

### The `:Fl` command

Fold again with the last used pattern

### The `:Fc` command

Show or modify current *context* lines around matching pattern.

For a description of the optional *context* option please see |:Fw|

### The `:Fi` command

Increment *context* by one line.

### The `:Fd` command

Decrement *context* by one line.

### The `:Fe` command

Set modified fold options to their previous value and end foldsearch.

### The `:FoldsearchDebugShow` command

Show debug messages. The debug level can be modified using the setting
`g:foldsearch_debug`. The number of debug message lines is limited to the value
of the setting `g:foldsearch_debug_lines`

### The `:FoldsearchDebugDump` command

Dump debug messages to given file. The debug level can be modified using the
setting `g:foldsearch_debug`. The number of debug message lines is limited to
the value of the setting `g:foldsearch_debug_lines`

## Mappings

  - `<Leader>fw` : `:Fw` with current context
  - `<Leader>fs` : `:Fs` with current context
  - `<Leader>fS` : `:FS`
  - `<Leader>ft` : `:Ft`
  - `<Leader>fl` : `:Fl`
  - `<Leader>fi` : `:Fi`
  - `<Leader>fd` : `:Fd`
  - `<Leader>fe` : `:Fe`

Mappings can be disabled by setting |g:foldsearch_disable_mappings| to 1

## Settings

Use: `let g:option_name=option_value` to set them in your global vimrc.

### The `g:foldsearch_highlight` setting

Highlight the pattern used for folding.

  - Value `0`: Don't highlight pattern
  - Value `1`: Highlight pattern
  - Default: `0`

### The `g:foldsearch_disable_mappings` setting

Disable the mappings. Use this to define your own mappings or to use the
plugin via commands only.

  - Value `0`: Don't disable mappings (use mappings)
  - Value `1`: Disable Mappings
  - Default: `0`

### The `g:foldsearch_scope` setting

Scope for which pattern, display context, original view etc. are stored.
If `window` is used, then different types of foldsearch can be done for the
same buffer displayed in several windows. if `buffer? is used, then different
types of foldsearch can be done for several buffers displayed in the same
window.

  - Value `window`: Use window scope to store data
  - Value `buffer`: Use buffer scope to store data
  - Default: `window`

### The `g:foldsearch_debug` setting

Debug level for storing debug messages in an internal buffer.

  - Value `0`: Don't store any debug message.
  - Value > `1`: Store debug messages up to the given level
  - Default: `0`

### The `g:foldsearch_debug_lines` setting

Number of debug messages stored in the internal buffer. If there are more debug
messages than the given number then the oldest messages will be removed from
the buffer.

  - Default: `100`

## Contribute

To contact the author (Markus Braun), please send an email to <markus.braun@krawel.de>

If you think this plugin could be improved, fork on [GitHub] and send a pull
request or just tell me your ideas.

## Credits

  - Karl Mowatt-Wilson for bug reports
  - John Appleseed for patches
  - Adam Szaj for the idea of different scopes

## Changelog

vX.Y.Z : XXXX-XX-XX

  - add debug messages and functions to dump them on the screen or to a file.
  - internal refactoring

v1.3.1 : 2024-04-26

  - bugfix: repeated call to `:Fe` removed folding markers in file

v1.3.0 : 2024-04-25

  - add ability to toggle between foldsearch and original view with `:Ft`
  - respect 'ignorecase' setting for pattern highlighting
  - bugfix: refactoring to make `:Fc` work again
  - bugfix: disable autocommands when restoring previous view to prevent unexpected side effects
  - bugfix: for unnamed buffers folds were not correctly restored when foldsearch is finished

v1.2.0 : 2023-10-01

  - add abilitiy to choose the scope of foldsearch commands

v1.1.1 : 2014-12-17

  - bugfix: add missing `call` to ex command

v1.1.0 : 2014-12-15

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


[GitHub]: https://github.com/embear/vim-foldsearch
[VIM online]: http://www.vim.org/scripts/script.php?script_id=2302
