" Name:    foldsearch.vim
" Version: 1.2.0
" Author:  Markus Braun <markus.braun@krawel.de>
" Summary: Vim plugin to fold away lines that don't match a pattern
" Licence: This program is free software: you can redistribute it and/or modify
"          it under the terms of the GNU General Public License as published by
"          the Free Software Foundation, either version 3 of the License, or
"          (at your option) any later version.
"
"          This program is distributed in the hope that it will be useful,
"          but WITHOUT ANY WARRANTY; without even the implied warranty of
"          MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"          GNU General Public License for more details.
"
"          You should have received a copy of the GNU General Public License
"          along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
"
" Section: Plugin header {{{1

" initialize "foldsearch_data" {{{2
let s:foldsearch_data = {}

" Section: Functions {{{1

" Function: foldsearch#foldsearch#GetConfig() {{{2
"
" Get the foldsearch configuration for the user defined scope.
"
function foldsearch#foldsearch#GetConfig()
  let scope = g:Foldsearch_scope_id()
  if has_key(s:foldsearch_data, scope)
    return s:foldsearch_data[scope]
  else
    return {
          \ 'pattern' : '',
          \ 'context_pre': 0,
          \ 'context_post': 0,
          \ 'viewfile': '',
          \ 'foldtext': '',
          \ 'foldmethod': '',
          \ 'foldenable': '',
          \ 'foldminlines': '',
          \ 'highlight_id': '',
          \ }
  endif
endfunction

" Function: foldsearch#foldsearch#GetConfig(config) {{{2
"
" Set the foldsearch configuration for the user defined scope.
"
function foldsearch#foldsearch#SetConfig(config)
  let s:foldsearch_data[g:Foldsearch_scope_id()] = a:config
endfunction

" Function: foldsearch#foldsearch#FoldCword(...) {{{2
"
" Search and fold the word under the cursor. Accept a optional context argument.
"
function! foldsearch#foldsearch#FoldCword(...)
  " get configuration for this scope
  let config = foldsearch#foldsearch#GetConfig()

  " define the search pattern
  let config.pattern = '\<'.expand("<cword>").'\>'

  " determine the number of context lines
  if (a:0 ==  0)
    call foldsearch#foldsearch#FoldSearchDo(config)
  elseif (a:0 == 1)
    call foldsearch#foldsearch#FoldSearchContext(config, a:1)
  elseif (a:0 == 2)
    call foldsearch#foldsearch#FoldSearchContext(config, a:1, a:2)
  endif

  " save configuration for this scope
  call foldsearch#foldsearch#SetConfig(config)
endfunction

" Function: foldsearch#foldsearch#FoldSearch(...) {{{2
"
" Search and fold the last search pattern. Accept a optional context argument.
"
function! foldsearch#foldsearch#FoldSearch(...)
  " get configuration for this scope
  let config = foldsearch#foldsearch#GetConfig()

  " define the search pattern
  let config.pattern = @/

  " determine the number of context lines
  if (a:0 == 0)
    call foldsearch#foldsearch#FoldSearchDo(config)
  elseif (a:0 == 1)
    call foldsearch#foldsearch#FoldSearchContext(config, a:1)
  elseif (a:0 == 2)
    call foldsearch#foldsearch#FoldSearchContext(config, a:1, a:2)
  endif

  " save configuration for this scope
  call foldsearch#foldsearch#SetConfig(config)
endfunction

" Function: foldsearch#foldsearch#FoldPattern(pattern) {{{2
"
" Search and fold the given regular expression.
"
function! foldsearch#foldsearch#FoldPattern(pattern)
  " get configuration for this scope
  let config = foldsearch#foldsearch#GetConfig()

  " define the search pattern
  let config.pattern = a:pattern

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo(config)

  " save configuration for this scope
  call foldsearch#foldsearch#SetConfig(config)
endfunction

" Function: foldsearch#foldsearch#FoldSpell(...)  {{{2
"
" do the search and folding based on spellchecker
"
function! foldsearch#foldsearch#FoldSpell(...)
  " get configuration for this scope
  let config = foldsearch#foldsearch#GetConfig()

  " if foldsearch_pattern is not defined, then exit
  if (!&spell)
    echo "Spell checking not enabled, ending Foldsearch"
    return
  endif

  let config.pattern = ''

  " do the search (only search for the first spelling error in line)
  let lnum = 1
  while lnum <= line("$")
    let bad_word = spellbadword(getline(lnum))[0]
    if bad_word != ''
      if empty(config.pattern)
        let config.pattern = '\<\(' . bad_word
      else
        let config.pattern = config.pattern . '\|' . bad_word
      endif
    endif
    let lnum = lnum + 1
  endwhile

  let config.pattern = config.pattern . '\)\>'

  " report if pattern not found and thus no fold created
  if (empty(config.pattern))
    echo "No spelling errors found!"
  else
    " determine the number of context lines
    if (a:0 == 0)
      call foldsearch#foldsearch#FoldSearchDo(config)
    elseif (a:0 == 1)
      call foldsearch#foldsearch#FoldSearchContext(config, a:1)
    elseif (a:0 == 2)
      call foldsearch#foldsearch#FoldSearchContext(config, a:1, a:2)
    endif
  endif

  " save configuration for this scope
  call foldsearch#foldsearch#SetConfig(config)
endfunction

" Function: foldsearch#foldsearch#FoldLast(...) {{{2
"
" Search and fold the last pattern
"
function! foldsearch#foldsearch#FoldLast()
  " get configuration for this scope
  let config = foldsearch#foldsearch#GetConfig()

  if (empty(config.pattern))
    return
  endif

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo(config)

  " save configuration for this scope
  call foldsearch#foldsearch#SetConfig(config)
endfunction

" Function: foldsearch#foldsearch#FoldSearchContext(config, ...) {{{2
"
" Set the context of the folds to the given value
"
function! foldsearch#foldsearch#FoldSearchContext(config, ...)
  if (a:0 == 0)
    " if no new context is given display current and exit
    echo "Foldsearch context: pre=".a:config.context_pre." post=".a:config.context_post
    return
  else
    let number=1
    let a:config.context_pre = 0
    let a:config.context_post = 0
    while number <= a:0
      execute "let argument = a:" . number . ""
      if (strpart(argument, 0, 1) == "-")
	let a:config.context_pre = strpart(argument, 1)
      elseif (strpart(argument, 0, 1) == "+")
	let a:config.context_post = strpart(argument, 1)
      else
	let a:config.context_pre = argument
	let a:config.context_post = argument
      endif
      let number = number + 1
    endwhile
  endif

  if (a:config.context_pre < 0)
    let a:config.context_pre = 0
  endif
  if (a:config.context_post < 0)
    let a:config.context_post = 0
  endif

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo(a:config)
endfunction

" Function: foldsearch#foldsearch#FoldContextAdd(change) {{{2
"
" Change the context of the folds by the given value.
"
function! foldsearch#foldsearch#FoldContextAdd(change)
  " get configuration for this scope
  let config = foldsearch#foldsearch#GetConfig()

  let config.context_pre = config.context_pre + a:change
  let config.context_post = config.context_post + a:change

  if (config.context_pre < 0)
    let config.context_pre = 0
  endif
  if (config.context_post < 0)
    let config.context_post = 0
  endif

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo(config)

  " save configuration for this scope
  call foldsearch#foldsearch#SetConfig(config)
endfunction

" Function: foldsearch#foldsearch#FoldSearchInit(config) {{{2
"
" initialize fold searching for current buffer
"
function! foldsearch#foldsearch#FoldSearchInit(config)
  " save current setup
  if (empty(a:config.viewfile))
    " save user settings before making changes
    let a:config.foldtext = &foldtext
    let a:config.foldmethod = &foldmethod
    let a:config.foldenable = &foldenable
    let a:config.foldminlines = &foldminlines

    " modify settings
    let &foldtext = ""
    let &foldmethod = "manual"
    let &foldenable = 1
    let &foldminlines = 0

    " create a file for view options
    let a:config.viewfile = tempname()

    " make a view of the current file for later restore of manual folds
    let l:viewoptions = &viewoptions
    let &viewoptions = "folds"
    execute "mkview " . a:config.viewfile
    let &viewoptions = l:viewoptions

    " for unnamed buffers, an 'enew' command gets added to the view which we
    " need to filter out.
    let l:lines = readfile(a:config.viewfile)
    call filter(l:lines, 'v:val != "enew"')
    call writefile(l:lines, a:config.viewfile)
  endif

  " erase all folds to begin with
  normal! zE
endfunction

" Function: foldsearch#foldsearch#FoldSearchDo(config)  {{{2
"
" do the search and folding based on config.pattern and
" config.context
"
function! foldsearch#foldsearch#FoldSearchDo(config)
  " if foldsearch_pattern is not defined, then exit
  if (empty(a:config.pattern))
    echo "No search pattern defined, ending fold search"
    return
  endif

  " initialize fold search for this buffer
  call foldsearch#foldsearch#FoldSearchInit(a:config)

  " highlight search pattern if requested
  if (g:foldsearch_highlight == 1)
    if (!empty(a:config.highlight_id))
      call matchdelete(a:config.highlight_id)
    endif
    let a:config.highlight_id = matchadd("Search", a:config.pattern)
  endif

  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  " move to the end of the file
  normal! $G$
  let pattern_found = 0      " flag to set when search pattern found
  let fold_created = 0       " flag to set when a fold is found
  let flags = "w"            " allow wrapping in the search
  let line_fold_start =  0   " set marker for beginning of fold

  " do the search
  while search(a:config.pattern, flags) > 0
    " patern had been found
    let pattern_found = 1

    " determine end of fold
    let line_fold_end = line(".") - 1 - a:config.context_pre

    " validate line of fold end and set fold
    if (line_fold_end >= line_fold_start && line_fold_end != 0)
      " create fold
      execute ":" . line_fold_start . "," . line_fold_end . " fold"

      " at least one fold has been found
      let fold_created = 1
    endif

    " jump to the end of this match. needed for multiline searches
    call search(a:config.pattern, flags . "ce")

    " update marker
    let line_fold_start = line(".") + 1 + a:config.context_post

    " turn off wrapping
    let flags = "W"
  endwhile

  " now create the last fold which goes to the end of the file.
  normal! $G
  let  line_fold_end = line(".")
  if (line_fold_end  >= line_fold_start && pattern_found == 1)
    execute ":". line_fold_start . "," . line_fold_end . "fold"
  endif

  " report if pattern not found and thus no fold created
  if (pattern_found == 0)
    echo "Pattern not found!"
  elseif (fold_created == 0)
    echo "No folds created"
  else
    echo "Foldsearch done"
  endif

  " restore position before folding
  execute cursor_position

  " make this position the vertical center
  normal! zz

endfunction

" Function: foldsearch#foldsearch#FoldSearchEnd() {{{2
"
" End the fold search and restore the saved settings
"
function! foldsearch#foldsearch#FoldSearchEnd()
  " get configuration for this scope
  let config = foldsearch#foldsearch#GetConfig()

  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  " restore the folds before foldsearch
  if (!empty(config.viewfile))
    execute "silent! source " . config.viewfile
    call delete(config.viewfile)
    let config.viewfile = ''

    " restore user settings before making changes
    let &foldtext = config.foldtext
    let &foldmethod = config.foldmethod
    let &foldenable = config.foldenable
    let &foldminlines = config.foldminlines
  endif

  " delete highlighting
  if (!empty(config.highlight_id))
    call matchdelete(config.highlight_id)
    let config.highlight_id = ''
  endif

  " give a message to the user
  echo "Foldsearch ended"

  " open all folds for the current cursor position
  normal! zv

  " restore position before folding
  execute cursor_position

  " make this position the vertical center
  normal! zz

  " save configuration for this scope
  call foldsearch#foldsearch#SetConfig(config)
endfunction

" Function: foldsearch#foldsearch#FoldSearchDebug(level, text) {{{2
"
" output debug message, if this message has high enough importance
"
function! foldsearch#foldsearch#FoldSearchDebug(level, text)
  if (g:foldsearch_debug >= a:level)
    echom "foldsearch: " . a:text
  endif
endfunction

" vim600: foldmethod=marker foldlevel=1 :
