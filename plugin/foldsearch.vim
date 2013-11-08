" Name:    foldsearch.vim
" Version: 1.0.0
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
" Section: Plugin header {{{1

" guard against multiple loads {{{2
if (exists("g:loaded_foldsearch") || &cp)
  finish
endi
let g:loaded_foldsearch = 1

" check for correct vim version {{{2
" matchadd() requires at least 7.1.40
if !(v:version > 701 || (v:version == 701 && has("patch040")))
  finish
endif

" define default "foldsearch_highlight" {{{2
if (!exists("g:foldsearch_highlight"))
  let g:foldsearch_highlight = 0
endif

" define default "foldsearch_disable_mappings" {{{2
if (!exists("g:foldsearch_disable_mappings"))
  let g:foldsearch_disable_mappings = 0
endif

" define default "foldsearch_debug" {{{2
if (!exists("g:foldsearch_debug"))
  let g:foldsearch_debug = 0
endif

" Section: Functions {{{1

" Function: s:FoldCword(...) {{{2
"
" Search and fold the word under the cursor. Accept a optional context argument.
"
function! s:FoldCword(...)
  " define the search pattern
  let b:foldsearch_pattern = '\<'.expand("<cword>").'\>'

  " determine the number of context lines
  if (a:0 ==  0)
    call s:FoldSearchDo()
  elseif (a:0 == 1)
    call s:FoldSearchContext(a:1)
  elseif (a:0 == 2)
    call s:FoldSearchContext(a:1, a:2)
  endif

endfunction

" Function: s:FoldSearch(...) {{{2
"
" Search and fold the last search pattern. Accept a optional context argument.
"
function! s:FoldSearch(...)
  " define the search pattern
  let b:foldsearch_pattern = @/

  " determine the number of context lines
  if (a:0 == 0)
    call s:FoldSearchDo()
  elseif (a:0 == 1)
    call s:FoldSearchContext(a:1)
  elseif (a:0 == 2)
    call s:FoldSearchContext(a:1, a:2)
  endif

endfunction

" Function: s:FoldPattern(pattern) {{{2
"
" Search and fold the given regular expression.
"
function! s:FoldPattern(pattern)
  " define the search pattern
  let b:foldsearch_pattern = a:pattern

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldSpell(...)  {{{2
"
" do the search and folding based on spellchecker
"
function! s:FoldSpell(...)
  " if foldsearch_pattern is not defined, then exit
  if (!&spell)
    echo "Spell checking not enabled, ending Foldsearch"
    return
  endif

  let b:foldsearch_pattern = ''

  " do the search (only search for the first spelling error in line)
  let lnum = 1
  while lnum <= line("$")
    let bad_word = spellbadword(getline(lnum))[0]
    if bad_word != ''
      if empty(b:foldsearch_pattern)
        let b:foldsearch_pattern = '\<\(' . bad_word
      else
        let b:foldsearch_pattern = b:foldsearch_pattern . '\|' . bad_word
      endif
    endif
    let lnum = lnum + 1
  endwhile

  let b:foldsearch_pattern = b:foldsearch_pattern . '\)\>'

  " report if pattern not found and thus no fold created
  if (empty(b:foldsearch_pattern))
    echo "No spelling errors found!"
  else
    " determine the number of context lines
    if (a:0 == 0)
      call s:FoldSearchDo()
    elseif (a:0 == 1)
      call s:FoldSearchContext(a:1)
    elseif (a:0 == 2)
      call s:FoldSearchContext(a:1, a:2)
    endif
  endif

endfunction

" Function: s:FoldLast(...) {{{2
"
" Search and fold the last pattern
"
function! s:FoldLast()
  if (!exists("b:foldsearch_context_pre") || !exists("b:foldsearch_context_post") || !exists("b:foldsearch_pattern"))
    return
  endif

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldSearchContext(context) {{{2
"
" Set the context of the folds to the given value
"
function! s:FoldSearchContext(...)
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif

  if (a:0 == 0)
    " if no new context is given display current and exit
    echo "Foldsearch context: pre=".b:foldsearch_context_pre." post=".b:foldsearch_context_post
    return
  else
    let number=1
    let b:foldsearch_context_pre = 0
    let b:foldsearch_context_post = 0
    while number <= a:0
      execute "let argument = a:" . number . ""
      if (strpart(argument, 0, 1) == "-")
	let b:foldsearch_context_pre = strpart(argument, 1)
      elseif (strpart(argument, 0, 1) == "+")
	let b:foldsearch_context_post = strpart(argument, 1)
      else
	let b:foldsearch_context_pre = argument
	let b:foldsearch_context_post = argument
      endif
      let number = number + 1
    endwhile
  endif

  if (b:foldsearch_context_pre < 0)
    let b:foldsearch_context_pre = 0
  endif
  if (b:foldsearch_context_post < 0)
    let b:foldsearch_context_post = 0
  endif

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldContextAdd(change) {{{2
"
" Change the context of the folds by the given value.
"
function! s:FoldContextAdd(change)
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif

  let b:foldsearch_context_pre = b:foldsearch_context_pre + a:change
  let b:foldsearch_context_post = b:foldsearch_context_post + a:change

  if (b:foldsearch_context_pre < 0)
    let b:foldsearch_context_pre = 0
  endif
  if (b:foldsearch_context_post < 0)
    let b:foldsearch_context_post = 0
  endif

  " call the folding function
  call s:FoldSearchDo()
endfunction

" Function: s:FoldSearchInit() {{{2
"
" initialize fold searching for current buffer
"
function! s:FoldSearchInit()
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif
  if (!exists("b:foldsearch_foldsave"))
    let b:foldsearch_foldsave = 0
  endif

  " save state if needed
  if (b:foldsearch_foldsave == 0)
    let b:foldsearch_foldsave = 1

    " make a view of the current file for later restore of manual folds
    let b:foldsearch_viewoptions = &viewoptions
    let &viewoptions = "folds,options"
    let b:foldsearch_viewfile = tempname()
    execute "mkview " . b:foldsearch_viewfile
    " For unnamed buffers, an 'enew' command gets added to the view which we
    " need to filter out.
    let l:lines = readfile(b:foldsearch_viewfile)
    call filter(l:lines, 'v:val != "enew"')
    call writefile(l:lines, b:foldsearch_viewfile)
  endif

  let &foldtext = ""
  let &foldmethod = "manual"
  let &foldenable = 1
  let &foldminlines = 0

  " erase all folds to begin with
  normal zE
endfunction

" Function: s:FoldSearchDo()  {{{2
"
" do the search and folding based on b:foldsearch_pattern and
" b:foldsearch_context
"
function! s:FoldSearchDo()
  " if foldsearch_pattern is not defined, then exit
  if (!exists("b:foldsearch_pattern"))
    echo "No search pattern defined, ending fold search"
    return
  endif

  " initialize fold search for this buffer
  call s:FoldSearchInit()

  " highlight search pattern if requested
  if (g:foldsearch_highlight == 1)
    if (exists("b:foldsearch_highlight_id"))
      matchdelete(b:foldsearch_highlight_id)
    endif
    let b:foldsearch_highlight_id = matchadd("Search", b:foldsearch_pattern)
  endif

  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  " move to the end of the file
  normal $G$
  let pattern_found = 0      " flag to set when search pattern found
  let fold_created = 0       " flag to set when a fold is found
  let flags = "w"            " allow wrapping in the search
  let line_fold_start =  0   " set marker for beginning of fold

  " do the search
  while search(b:foldsearch_pattern, flags) > 0
    " patern had been found
    let pattern_found = 1

    " determine end of fold
    let line_fold_end = line(".") - 1 - b:foldsearch_context_pre

    " validate line of fold end and set fold
    if (line_fold_end >= line_fold_start && line_fold_end != 0)
      " create fold
      execute ":" . line_fold_start . "," . line_fold_end . " fold"

      " at least one fold has been found
      let fold_created = 1
    endif

    " jump to the end of this match. needed for multiline searches
    call search(b:foldsearch_pattern, flags . "ce")

    " update marker
    let line_fold_start = line(".") + 1 + b:foldsearch_context_post

    " turn off wrapping
    let flags = "W"
  endwhile

  " now create the last fold which goes to the end of the file.
  normal $G
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
  normal zz

endfunction

" Function: s:FoldSearchEnd() {{{2
"
" End the fold search and restore the saved settings
"
function! s:FoldSearchEnd()
  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  if (!exists('b:foldsearch_foldsave'))
    let b:foldsearch_foldsave = 0
  endif
  if (b:foldsearch_foldsave == 1)
    let b:foldsearch_foldsave = 0

    " restore the folds before foldsearch
    execute "silent! source " . b:foldsearch_viewfile
    call delete(b:foldsearch_viewfile)
    let &viewoptions = b:foldsearch_viewoptions

  endif

  " delete highlighting
  if (exists("b:foldsearch_highlight_id"))
    call matchdelete(b:foldsearch_highlight_id)
    unlet b:foldsearch_highlight_id
  endif

  " give a message to the user
  echo "Foldsearch ended"

  " open all folds for the current cursor position
  silent! execute "normal " . foldlevel(line(".")) . "zo"

  " restore position before folding
  execute cursor_position

  " make this position the vertical center
  normal zz

endfunction

" Function: s:FoldSearchDebug(level, text) {{{2
"
" output debug message, if this message has high enough importance
"
function! s:FoldSearchDebug(level, text)
  if (g:foldsearch_debug >= a:level)
    echom "foldsearch: " . a:text
  endif
endfunction

" Section: Commands {{{1

command! -nargs=* -complete=command Fs call s:FoldSearch(<f-args>)
command! -nargs=* -complete=command Fw call s:FoldCword(<f-args>)
command! -nargs=1 Fp call s:FoldPattern(<q-args>)
command! -nargs=* -complete=command FS call s:FoldSpell(<f-args>)
command! -nargs=0 Fl call s:FoldLast()
command! -nargs=* Fc call s:FoldSearchContext(<f-args>)
command! -nargs=0 Fi call s:FoldContextAdd(+1)
command! -nargs=0 Fd call s:FoldContextAdd(-1)
command! -nargs=0 Fe call s:FoldSearchEnd()

" Section: Mappings {{{1

if !g:foldsearch_disable_mappings
   map <Leader>fs :call <SID>FoldSearch()<CR>
   map <Leader>fw :call <SID>FoldCword()<CR>
   map <Leader>fS :call <SID>FoldSpell()<CR>
   map <Leader>fl :call <SID>FoldLast()<CR>
   map <Leader>fi :call <SID>FoldContextAdd(+1)<CR>
   map <Leader>fd :call <SID>FoldContextAdd(-1)<CR>
   map <Leader>fe :call <SID>FoldSearchEnd()<CR>
endif

" Section: Menu {{{1

if has("menu")
  amenu <silent> Plugin.FoldSearch.Context.Increment\ One\ Line :Fi<CR>
  amenu <silent> Plugin.FoldSearch.Context.Decrement\ One\ Line :Fd<CR>
  amenu <silent> Plugin.FoldSearch.Context.Show :Fc<CR>
  amenu <silent> Plugin.FoldSearch.Search :Fs<CR>
  amenu <silent> Plugin.FoldSearch.Current\ Word :Fw<CR>
  amenu <silent> Plugin.FoldSearch.Pattern :Fp
  amenu <silent> Plugin.FoldSearch.Spelling :FS<CR>
  amenu <silent> Plugin.FoldSearch.Last :Fl<CR>
  amenu <silent> Plugin.FoldSearch.End :Fe<CR>
endif

" vim600: foldmethod=marker foldlevel=0 :
