" File:		misc_map.vim
" Author:	Luc Hermitte <MAIL:hermitte {at} free {dot} fr>
" 		<URL:http://hermitte.free.fr/vim/>
" Last Update:	21st jul 2002
"
" Purpose:	Several mapping oriented functions
"
"---------------------------------------------------------------------------
" Function:	MapNoContext( key, sequence)				{{{
" Purpose:	Regarding the context of the current position of the
" 		cursor, it returns either the value of key or the
" 		interpreted value of sequence.
" Parameters:	<key> - returned while whithin comments, strings or characters 
" 		<sequence> - returned otherwise. In order to enable the
" 			interpretation of escaped caracters, <sequence>
" 			must be a double-quoted string. A backslash must be
" 			inserted before every '<' and '>' sign. Actually,
" 			the '<' after the second one (included) must be
" 			backslashed twice.
" Example:	A mapping of 'if' for C programmation :
"   inoremap if<space> <C-R>=MapNoContext("if ",
"   \				'\<c-f\>if () {\<cr\>}\<esc\>?)\<cr\>i')<CR>
" }}}
"---------------------------------------------------------------------------
" Function:	MapNoContext2( key, sequence)				{{{
" Purpose:	Exactly the same purpose than MapNoContext(). There is a
"		slight difference, the previous function is really boring
"		when we want to use variables like 'tarif' in the code.
"		So this function also returns <key> when the character
"		before the current cursor position is not a keyword
"		character ('h: iskeyword' for more info). 
" Hint:		Use MapNoContext2() for mapping keywords like 'if', etc.
"		and MapNoContext() for other mappings like parenthesis,
"		punctuations signs, and so on.
" }}}
"---------------------------------------------------------------------------
" Function:	BuildMapSeq( sequence )					{{{
" Purpose:	This fonction is to be used to generate the sequences used
" 		by the «MapNoContext» functions. It considers that every
" 		«¡.*!» pattern is associated to an INSERT-mode mapping and
" 		expand it.
" 		It is used to define marked mappings ; cf <c.set>
" }}}
"---------------------------------------------------------------------------
" Function:	MapAroundVisualLines(begin,end,isLine,isIndented) range {{{
" Purpose:	Ease the definition of visual mappings that add text
" 		around the selected one.
" Examples:
"   (*) LaTeX-like stuff
"       if &ft=="tex"
"         vnoremap == :call MapAroundVisualLines(
"		      \ '\begin{center}','\end{center}',1,1)<cr>
"   (*) C like stuff
"       elseif &ft=="c" || &ft=="cpp"
"         vnoremap == :call MapAroundVisualLines('else {','}',1,1)<cr>
"   (*) VIM-like stuff
"       elseif &ft=="vim" 
"         vnoremap == :call MapAroundVisualLines('if','endif',1,1)<cr>
"       endif

" Fixed Problem: 
" * if a word from 'begin' or 'end' is used as a terminaison of an
" abbreviation, this function yields to an incorrect behaviour. 
" Problems: 
" * Smartindent is not properly managed. [Vim 5.xx]
" Todo:
" * Add a positionning feature -> ?{<cr>a
" }}}
"===========================================================================
"
"---------------------------------------------------------------------------
" Avoid reinclusion
if !exists('g:misc_map_loaded')
  let g:misc_map_loaded = 1
  let cpop = &cpoptions
  set cpoptions-=C
"
if !exists(':Silent') " {{{
  if version < 600
    command! -nargs=+ -bang Silent exe "<args>"
  else
    command! -nargs=+                -bang Silent silent<bang> <args>
  endif
endif
" }}}
"---------------------------------------------------------------------------
function! MapNoContext(key, seq) " {{{
  let syn = synIDattr(synID(line('.'),col('.')-1,1),'name') 
  if syn =~? '\(comment\)\|\(string\)\|\(character\)'
    return a:key
  else
    ""return substitute( a:seq, "\<esc\>", "\<esc>", 'g' )
    exe 'return "' . 
      \   substitute( a:seq, '\\<\(.\{-}\)\\>', '"."\\<\1>"."', 'g' ) .  '"'
  endif 
endfunction
" }}}
"---------------------------------------------------------------------------
function! MapNoContext2(key, seq) " {{{
  let c = col('.')-1
  let l = line('.')
  let syn = synIDattr(synID(l,c,1),'name') 
  if syn =~? '\(comment\)\|\(string\)\|\(character\)'
    return a:key
  elseif getline(l)[c-1] =~ '\k'
    return a:key
  else
    exe 'return "' . 
      \   substitute( a:seq, '\\<\(.\{-}\)\\>', '"."\\<\1>"."', 'g' ) .  '"'
  endif 
endfunction
" }}}
"---------------------------------------------------------------------------
function! BuildMapSeq(seq) " {{{
  let r = ''
  let s = a:seq
  while strlen(s) != 0 " For every '¡.*!' pattern, extract it
    let r = r . substitute(s,'^\(.\{-}\)\(\(¡.\{-}!\)\(.*\)\)\=$', '\1', '')
    let c =     substitute(s,'^\(.\{-}\)\(\(¡.\{-}!\)\(.*\)\)\=$', '\3', '')
    let s =     substitute(s,'^\(.\{-}\)\(\(¡.\{-}!\)\(.*\)\)\=$', '\4', '')
    let m = mapcheck(c,'i')
    if strlen(m) != 0
      exe 'let m="' . substitute(m, '<\(.\{-}\)>', '"."\\<\1>"."', 'g') . '"'
      let r = r . m
    else
      let r = r . c
    endif
  endwhile
  exe 'return "' . 
    \   substitute( r, '\\<\(.\{-}\)\\>', '"."\\<\1>"."', 'g' ) .  '"'
endfunction
" }}}
"---------------------------------------------------------------------------
function! MapAroundVisualLines(begin,end,isLine,isIndented) range " {{{
  let pp = &paste
  set paste
  " 'H' stands for 'High' ; 'B' stands for 'Bottom' 
  " 'L' stands for 'Left', 'R' for 'Right'
  let HL = "`<i"
  let BL = "\<esc>`>a"
  let HR = "\<esc>"
  let BR = "\<esc>"
  " If visual-line mode macros -> jump between stuffs
  if a:isLine == 1
    let HR="\<cr>".HR
    let BL=BL."\<cr>"
  endif
  " If indentation is used
  if a:isIndented == 1
    if version < 600 " -----------Version 6.xx
      if &cindent == 1	" C like sources -> <c-f> defined
	let HR="\<c-f>".HR
	let BR="\<c-t>".BR
      else		" Otherwise like LaTeX, VIM
	let HR=HR.":>\<cr>"
	let BR=BR.":<\<cr>"
      endif
      let BL='>'.BL
    else " -----------------------Version 6.xx
      let HR=HR."gv``="
    endif
  endif
  " The substitute is here to compensate a little problem with HTML tags
  Silent exe "normal! gv". BL.substitute(a:end,'>',"\<c-v>>",'').BR.HL.a:begin.HR
  " 'gv' is used to refocus on the current visual zone
  "  call confirm(strtrans( "normal! gv". BL.a:end.BR.HL.a:begin.HR), "&Ok")
  let &paste=pp
endfunction
" }}}
"---------------------------------------------------------------------------
" Function: EatChar()	{{{
" Thanks to the VIM Mailing list
" NB: To make it work with VIM 5.x, replace the '? :' operator with an 'if
" then' test.
" This version does not support multi-bytes characters.
function! EatChar(pat)
  let c = nr2char(getchar())
  return (c =~ a:pat) ? '' : c
endfunction

command -narg=+ Iabbr execute "iabbr " <q-args>."<C-R>=EatChar('\\s')<CR>"
command -narg=+ Inoreabbr 
      \ execute "inoreabbr " <q-args>."<C-R>=EatChar('\\s')<CR>"

" }}}
"---------------------------------------------------------------------------
" Avoid reinclusion
  let &cpoptions = cpop
endif

"===========================================================================
" vim600: set fdm=marker:
