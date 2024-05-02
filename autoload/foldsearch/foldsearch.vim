" Name:    foldsearch.vim
" Version: 1.3.2
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

" define default "foldsearch_highlight" {{{2
if (!exists("g:foldsearch_highlight"))
  let g:foldsearch_highlight = 0
endif

" define default "foldsearch_debug" {{{2
if (!exists("g:foldsearch_debug"))
  let g:foldsearch_debug = 0
endif

" define default "foldsearch_debug_lines" {{{2
let s:foldsearch_debug_lines = 100
if (exists("g:foldsearch_debug_lines"))
  let s:foldsearch_debug_lines = g:foldsearch_debug_lines
endif

" define default "foldsearch_scope" {{{2
if (!exists("g:foldsearch_scope"))
  let s:Foldsearch_scope_id = function("win_getid")
elseif g:foldsearch_scope == "window"
  let s:Foldsearch_scope_id = function("win_getid")
elseif g:foldsearch_scope == "buffer"
  let s:Foldsearch_scope_id = function("bufnr")
else
  let s:Foldsearch_scope_id = function("win_getid")
endif

" initialize foldsearch_data {{{2
let s:foldsearch_data = {}

" initialize debug message buffer {{{2
let s:foldsearch_debug_message = []

" Section: Functions {{{1

" Function: foldsearch#foldsearch#FoldCword(...) {{{2
"
" Search and fold the word under the cursor. Accept a optional context argument.
"
function! foldsearch#foldsearch#FoldCword(...)
  call s:Debug(2, "BEGIN FoldCword()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  " define the search pattern
  let l:config.pattern = '\<'.expand("<cword>").'\>'

  " determine the number of context lines
  call s:UpdateContext(l:config, a:000)

  " do the actual search
  call s:DoFolding(l:config)

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldCword()")
endfunction

" Function: foldsearch#foldsearch#FoldSearch(...) {{{2
"
" Search and fold the last search pattern. Accept a optional context argument.
"
function! foldsearch#foldsearch#FoldSearch(...)
  call s:Debug(2, "BEGIN FoldSearch()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  " define the search pattern
  let l:config.pattern = @/

  " determine the number of context lines
  call s:UpdateContext(l:config, a:000)

  " do the actual search
  call s:DoFolding(l:config)

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldSearch()")
endfunction

" Function: foldsearch#foldsearch#FoldPattern(pattern) {{{2
"
" Search and fold the given regular expression.
"
function! foldsearch#foldsearch#FoldPattern(pattern)
  call s:Debug(2, "BEGIN FoldPattern()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  " define the search pattern
  let l:config.pattern = a:pattern

  " call the folding function
  call s:DoFolding(l:config)

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldPattern()")
endfunction

" Function: foldsearch#foldsearch#FoldSpell(...)  {{{2
"
" Do the search and folding based on spellchecker
"
function! foldsearch#foldsearch#FoldSpell(...)
  call s:Debug(2, "BEGIN FoldSpell()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  " if foldsearch_pattern is not defined, then exit
  if (!&spell)
    call s:Error("Spell checking not enabled, ending Foldsearch")
    call s:Debug(2, "END FoldSpell()")
    return
  endif

  let l:config.pattern = ''

  " do the search (only search for the first spelling error in line)
  let lnum = 1
  while lnum <= line("$")
    let bad_word = spellbadword(getline(lnum))[0]
    if bad_word != ''
      if empty(l:config.pattern)
        let l:config.pattern = '\<\(' . bad_word
      else
        let l:config.pattern = l:config.pattern . '\|' . bad_word
      endif
    endif
    let lnum = lnum + 1
  endwhile

  let l:config.pattern = l:config.pattern . '\)\>'

  " report if pattern not found and thus no fold created
  if (empty(l:config.pattern))
    call s:Message("No spelling errors found!")
  else
    " determine the number of context lines
    call s:UpdateContext(l:config, a:000)

    " do the actual search
    call s:DoFolding(l:config)
  endif

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldSpell()")
endfunction

" Function: foldsearch#foldsearch#FoldLast(...) {{{2
"
" Search and fold the last pattern
"
function! foldsearch#foldsearch#FoldLast()
  call s:Debug(2, "BEGIN FoldLast()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  " call the folding function
  call s:DoFolding(l:config)

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldLast()")
endfunction

" Function: foldsearch#foldsearch#FoldToggle() {{{2
"
" Toggle between fold search and saved view
"
function! foldsearch#foldsearch#FoldToggle()
  call s:Debug(2, "BEGIN FoldToggle()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  if (empty(l:config.active))
    call s:DoFolding(l:config)
  else
    call s:UndoFolding(l:config)
  endif

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldToggle()")
endfunction

" Function: foldsearch#foldsearch#FoldEnd() {{{2
"
" End the fold search and restore the saved settings
"
function! foldsearch#foldsearch#FoldEnd()
  call s:Debug(2, "BEGIN FoldEnd()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  " undo modification done for foldsearch
  call s:UndoFolding(l:config)

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldEnd()")
endfunction

" Function: foldsearch#foldsearch#FoldSearchContext(...) {{{2
"
" Set the context of the folds to the given value
"
function! foldsearch#foldsearch#FoldSearchContext(...)
  call s:Debug(2, "BEGIN FoldContext()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  if (a:0 == 0)
    " if no new context is given display current and exit
    call s:Message("Foldsearch context: pre = ".l:config.context_pre." lines; post = ".l:config.context_post . " lines")
  else
    call s:UpdateContext(l:config, a:000)
  endif

  " call the folding function
  call s:DoFolding(l:config)

  call s:Debug(2, "END FoldContext()")
endfunction

" Function: foldsearch#foldsearch#FoldContextAdd(change) {{{2
"
" Change the context of the folds by the given value.
"
function! foldsearch#foldsearch#FoldContextAdd(change)
  call s:Debug(2, "BEGIN FoldContextAdd()")

  " get configuration for this scope
  let l:config = s:GetConfig()

  let l:config.context_pre = l:config.context_pre + a:change
  let l:config.context_post = l:config.context_post + a:change

  if (l:config.context_pre < 0)
    let l:config.context_pre = 0
  endif
  if (l:config.context_post < 0)
    let l:config.context_post = 0
  endif

  " call the folding function
  call s:DoFolding(l:config)

  " save configuration for this scope
  call s:SetConfig(l:config)

  call s:Debug(2, "END FoldContextAdd()")
endfunction

" Function: foldsearch#foldsearch#FoldSearchDebugShow() {{{2
"
" output stored debug messages to console
"
function! foldsearch#foldsearch#FoldSearchDebugShow()
  for l:message in s:foldsearch_debug_message
    echo l:message
  endfor
endfunction

" Function: foldsearch#foldsearch#FoldSearchDebugDump(logfile) {{{2
"
" output stored debug message to file
"
function! foldsearch#foldsearch#FoldSearchDebugDump(logfile)
  call writefile(s:foldsearch_debug_message, a:logfile, "s")
endfunction

" Function: s:GetConfig() {{{2
"
" Get the foldsearch configuration for the user defined scope.
"
function s:GetConfig()
  let scope = s:Foldsearch_scope_id()
  if has_key(s:foldsearch_data, scope)
    call s:Debug(3, "use existing config")
    return s:foldsearch_data[scope]
  else
    call s:Debug(3, "initialize config")
    return {
          \ 'active' : 0,
          \ 'pattern' : '',
          \ 'context_pre': 0,
          \ 'context_post': 0,
          \ 'viewfile': '',
          \ 'highlight_id': '',
          \ }
  endif
endfunction

" Function: s:GetConfig(config) {{{2
"
" Set the foldsearch configuration for the user defined scope.
"
function s:SetConfig(config)
  let s:foldsearch_data[s:Foldsearch_scope_id()] = a:config
endfunction

" Function: s:Initialize(config) {{{2
"
" Initialize fold searching for current buffer in given config
"
function! s:Initialize(config)
  call s:Debug(2, "BEGIN Initialize()")

  " save current setup
  if (empty(a:config.viewfile))
    " create a file for view options
    let a:config.viewfile = tempname()

    " make a view of the current file for later restoring fold settings and  manual folds
    " NOTE: for unnamed buffers the view files does not store manually created
    "       folds and they will be lost!
    let l:viewoptions = &viewoptions
    let &viewoptions = "folds"
    execute "mkview " . a:config.viewfile
    let &viewoptions = l:viewoptions

    " alter commands in view file:
    "   - add current foldtext setting that is not automatically stored
    "   - add deletion of all folds that is missing for unnamed buffers
    "   - remove 'enew' command that gets added for unnamed buffers
    "   - remove 'doautoall' that might cause unwanted side effects
    let l:lines = readfile(a:config.viewfile)
    call s:Debug(3, "view file (unmodified):", l:lines)

    " prepend line(s)
    call insert(l:lines, 'silent! normal! zE')

    " append line(s)
    call insert(l:lines, 'setlocal fdt='.&foldtext, -1)

    " delete line(s)
    call filter(l:lines, 'v:val !~# "\\(^enew\\|^doautoall\\)"')

    call writefile(l:lines, a:config.viewfile, "S")
    call s:Debug(3, "view file (modified):", l:lines)

    " modify settings
    let &foldtext = ""
    let &foldmethod = "manual"
    let &foldenable = 1
    let &foldminlines = 0
  endif

  " delete all manual folds to get a clean starting point
  normal! zE

  call s:Debug(2, "END Initialize()")
endfunction

" Function: s:UpdateContext(config, ...) {{{2
"
" Update the context in the given config
"
function! s:UpdateContext(config, args)
  call s:Debug(2, "BEGIN UpdateContext()")

  let idx = 0
  while idx < len(a:args)
    if (strpart(a:args[idx], 0, 1) == "-")
      let a:config.context_pre = strpart(a:args[idx], 1)
    elseif (strpart(a:args[idx], 0, 1) == "+")
      let a:config.context_post = strpart(a:args[idx], 1)
    else
      let a:config.context_pre = a:args[idx]
      let a:config.context_post = a:args[idx]
    endif
    let idx = idx + 1
  endwhile

  if (a:config.context_pre < 0)
    let a:config.context_pre = 0
  endif
  if (a:config.context_post < 0)
    let a:config.context_post = 0
  endif

  call s:Debug(2, "END UpdateContext()")
endfunction

" Function: s:DoFolding(config)  {{{2
"
" Do the search and folding based on config.pattern and
" config.context
"
function! s:DoFolding(config)
  call s:Debug(2, "BEGIN DoFolding()")
  " if foldsearch_pattern is not defined, then exit
  if (empty(a:config.pattern))
    call s:Error("No search pattern defined, ending fold search")
    call s:Debug(2, "END DoFolding()")
    return
  endif

  " initialize fold search for this buffer
  call s:Initialize(a:config)

  " highlight search pattern if requested
  if (g:foldsearch_highlight == 1)
    if (!empty(a:config.highlight_id))
      call matchdelete(a:config.highlight_id)
    endif

    " in case of 'ignorecase' beeing set and the pattern does not force case
    " then modify the pattern to ignore case
    if &ignorecase == 1 && a:config.pattern !~# '\\\@<!\\C'
      let l:modifier = '\c'
    else
      let l:modifier = ''
    endif
    let a:config.highlight_id = matchadd("Search", l:modifier.a:config.pattern)
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
    call s:Message("Pattern not found!")
  elseif (fold_created == 0)
    call s:Message("No folds created")
  else
    call s:Message("Foldsearch done")
  endif

  " restore position before folding
  execute cursor_position

  " signal currently active fold search
  let a:config.active = 1

  call s:Debug(3, "config:", a:config)
  call s:Debug(2, "END DoFolding()")
endfunction

" Function: s:UndoFolding(config) {{{2
"
" End the fold search and restore the saved settings
"
function! s:UndoFolding(config)
  call s:Debug(2, "BEGIN UndoFolding()")

  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  " restore the folds before foldsearch
  if (!empty(a:config.viewfile))
    " restore folds
    execute "silent! source " . a:config.viewfile
    call delete(a:config.viewfile)
    let a:config.viewfile = ''
  endif

  " delete highlighting
  if (!empty(a:config.highlight_id))
    call matchdelete(a:config.highlight_id)
    let a:config.highlight_id = ''
  endif

  " give a message to the user
  call s:Message("Foldsearch ended")

  " restore position before folding
  execute cursor_position

  " signal currently inactive fold search
  let a:config.active = 0

  call s:Debug(2, "END UndoFolding()")
endfunction

" Function: s:Message(text) {{{2
"
" output normal user message
"
function! s:Message(text)
  echo a:text

  " put every message to the debug message array
  call s:Debug(1, a:text)
endfunction

" Function: s:Error(text) {{{2
"
" output error message
"
function! s:Error(text)
  echohl ErrorMsg | echom a:text | echohl None

  " put every error message to the debug message array
  call s:Debug(1, a:text)
endfunction

" Function: s:Debug(level, text) {{{2
"
" output debug message, if this message has high enough importance
"
function! s:Debug(level, ...)
  if (g:foldsearch_debug >= a:level)
    " print stacktrace for levels above 10
    if (g:foldsearch_debug >= 10)
      call add(s:foldsearch_debug_message, "lvl X: stacktrace " . expand('<sfile>'))
    endif

    let l:output ="lvl " . a:level . ":"
    for arg in a:000
      if type(arg) != type("")
        let l:output .= " " . string(arg)
      else
        let l:output .= " " . arg
      endif
    endfor

    " actual message
    call add(s:foldsearch_debug_message, output)

    " if the list is too long remove the first element
    if len(s:foldsearch_debug_message) > s:foldsearch_debug_lines
      call remove(s:foldsearch_debug_message, 0)
    endif
  endif
endfunction

" vim600: foldmethod=marker foldlevel=1 :
