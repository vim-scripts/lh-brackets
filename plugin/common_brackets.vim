" File:		common_brackets.vim
" Author:	Luc Hermitte <MAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim/>
" Last Update:	04th apr 2002
" Version 3.4:	* Works correctly when editing several files (like with 
" 		"vim foo1.x foo2.x").
" 		* ')' and '}' don't search for the end of the bracket when we
" 		are within a comment.
" Version 3.3:	* Add support for \{, \(, \[, \<
"               * Plus some functions to change the type of brackets and
"               toggle backslashes before brackets.
"               Inspired from AucTeX.vim.
" Version 3.2:	* Bugs fixed with {
" Version 3.1:	* Triggers.vim and help.vim used, but not required.
" Version 3.0:	* Pure VIM6
" Version 2.1a:	* Some little change with the requirements
" Version 2.1:	* Use b:usemarks in the mapping of curly-brackets
" Version 2.0:	* Lately, I've discovered (SR) Stephen Riehm's bracketing
" 		macros and felt in love with the markers feature. So, here is
" 		the ver 2.x based on his package.
" 		I still bring an original feature : a centralized way to
" 		customize these pairs regarding options specified within
" 		the ftplugins.
" 		Note that I planned to use this file with my customized
" 		version of Stephan Riehm's file.
" 
" Purpose:	This file defines a function (Brackets) that brings
" 		together several macros dedicated to insert pairs of
" 		caracters when the first one is typed. Typical examples are
" 		the parenthesis, brackets, <,>, etc. 
" 		One can choose the macro he wants to activate thanks to the
" 		buffer-relative options listed below.
"
" 		This function is used by different setting files
" 		(ftplugins) : <vim_set.vim>, <ML_set.vim>, <html_set.vim>,
" 		<php_set.vim> and <tex_set.vim> -- available on my VIM web
" 		site.
"
" 		BTW, they can be activated or desactivated by pressing <F9>
" 		Rem.: exe "noremap" is not yet supported by Triggers.vim
" 		Hence the trick with the intermediary functions.
"
" Options:	(*) b:cb_bracket	: [ -> [ & ]
"		(*) b:cb_cmp		: < -> < & >
"		    could be customized thanks to b:cb_ltFn and b:cb_gtFn
"		    cf <ML.set>
"		(*) b:cb_acco		: { -> { & }
"		(*) b:cb_parent		: ( -> ( & )
"		(*) b:cb_mathMode	: $ -> $ & $		[tex_set.vim]
"		    type $$ in visual/normal mode
"		(*) b:cb_quotes		: ' -> ' & '
"			== 2  => non active within comment or strings
"		(*) b:cb_Dquotes	: " -> " & "
"		    could be customized thanks to b:cb_DqFn ;	[vim_set.vim]
"			== 2  => non active within comment or strings
"		(*) b:usemarks		: 
"			indicates the wish to use the marking feature first
"			defined by Stephan Riehm.
"
" Dependancies:	Triggers.vim		(&fileuptodate.vim), (Not required)
" 		misc_map.vim		(MapNoContext()),    (required)
" 		bracketing.base.vim	(¡mark! & ¡jump!)    (required)
" 		help.vim for vimrc_core.vim (:VimrcHelp)     (recognized and used.)
" 		
"===========================================================================
"
"======================================================================

" ------------------------------------------------------------------
" The main function that defines all the key-bindings.
function! Brackets()
  " [ & ]
  if exists('b:cb_bracket') && b:cb_bracket
    vnoremap <buffer> [ <esc>`>a]<esc>`<i[<esc>%
"        imap <buffer> [ <C-V>[<C-V>]¡mark!<ESC>F]i
    inoremap <buffer> [ <C-R>=<sid>EscapableBrackets('[','\<C-V\>[','\<C-V\>]')<cr>
        nmap <buffer> [ viw[
	nmap <buffer> <M-[> viw[
	imap <buffer> <M-[> <esc><M-[>a
    "inoremap <buffer> ] <esc>/]/<cr>a
  endif
  "
  " < & >
  if exists('b:cb_cmp') && b:cb_cmp
    imap <buffer> < <c-r>=Brkt_lt()<cr>
    imap <buffer> > <c-r>=Brkt_gt()<cr>
    vnoremap <buffer> < <esc>`>a><esc>`<i<<esc>`>ll
        "nmap <buffer> < viw<
	nmap <buffer> <M-<> viw<
	imap <buffer> <M-<> <esc><M-<>a
  endif
  "
  " { & }
  if exists('b:cb_acco') && b:cb_acco
    if &syntax == "tex"
      inoremap <buffer> { <C-R>=<sid>EscapableBrackets('{','{','}')<cr>
    else
      inoremap <buffer> { <C-R>=<sid>Def_Map1('{','{\<cr\>}\<esc\>O','{\<cr\>}¡mark!\<esc\>O')<cr>
"      inoremap <buffer> { <C-R>=<sid>EscapableBracketsLn('{','{','}')<cr>
      inoremap <buffer> #{ <C-R>=<sid>Def_Map1('#{','{}\<esc\>i','{}¡mark!\<esc\>?{\<cr\>a')<cr>
    endif
    vnoremap <buffer> { <esc>`>a}<esc>`<i{<esc>%
        nmap <buffer> { viw{
        ""nmap <buffer> <M-{> viw{
        ""imap <buffer> <M-{> <esc><M-{>a
    nnoremap <buffer> } /}\\|\.\\|\$\\|&\\|]<CR>a
    ""imap <buffer> ¡find}! <esc>}
    ""inoremap <buffer> } <c-r>=MapNoContext('}',BuildMapSeq('¡find}!'))<cr>
        imap <buffer> } <C-R>=MapNoContext('}', '\<c-o\>}\<left\>')<CR>
  endif
  "
  " ( & )
  if exists('b:cb_parent') && b:cb_parent
    inoremap <buffer> ( <C-R>=<sid>EscapableBrackets('(','(',')')<cr>
     noremap <buffer> ) /)/<cr>a
        imap <buffer> ) <C-R>=MapNoContext(')', '\<c-o\>/)/e+1/\<cr\>')<CR>
    vnoremap <buffer> ( <esc>`>a)<esc>`<i(<esc>%
        nmap <buffer> ( viw(
        nmap <buffer> <M-(> viw(
        imap <buffer> <M-(> <esc><M-(>a
  endif

  " $ & $
  if exists('b:cb_mathMode') && b:cb_mathMode
    inoremap <buffer> $ <c-r>=Insert_LaTeX_Dollar()<cr>
    vnoremap <buffer> $$ <ESC>`>a$<ESC>`<i$<ESC>`>ll
	nmap <buffer> $$ viw$$
	nmap <buffer> <M-$> viw$$
	imap <buffer> <M-$> <esc><M-$>
  endif
  "
  " quotes
  if exists('b:cb_quotes') && b:cb_quotes
    inoremap <buffer> ' <c-r>=Brkt_quote()<cr>
    vnoremap <buffer> '' <esc>`>a'<esc>`<i'<esc>`>ll
        nmap <buffer> ''    viw''
	nmap <buffer> <M-'> viw''
	" add quotes around the word under the cursor
	imap <buffer> <M-'> <esc><M-'>a
  endif
  "
  " double-quotes
  if exists('b:cb_Dquotes') && b:cb_Dquotes
    inoremap <buffer> " <c-r>=Brkt_Dquote()<cr>
    vnoremap <buffer> "" <esc>`>a"<esc>`<i"<esc>`>ll
	nmap <buffer> ""    viw""
	nmap <buffer> <M-"> viw""
	" add doqutes around the word under the cursor
	imap <buffer> <M-"> <esc><M-">a
  endif
endfunction

" Defines a command and the mode switching mappings (with <F9>)
if !exists("*Trigger_Function")
  runtime plugin/Triggers.vim
endif
if exists("*Trigger_Function")
  au Bufenter * :call <SID>LoadBrackets()
  let s:scriptname = expand("<sfile>:p")

  function! s:LoadBrackets()
    if exists("b:loaded_comman_bracket_buff") | return | endif
    let b:loaded_comman_bracket_buff = 1
    silent call Trigger_Function('<F9>', 'Brackets', s:scriptname,1,1)
    imap <buffer> <F9> <SPACE><ESC><F9>a<BS>
    silent call Trigger_DoSwitch('<M-F9>',':let b:usemarks=1',':let b:usemarks=0',1,1)
    imap <buffer> <M-F8> <SPACE><ESC><M-F9>a<BS>
  endfunction
endif

"======================================================================
if exists("g:loaded_common_brackets_vim") | finish | endif
let g:loaded_common_brackets_vim = 1

" Jump point macros
" =================
" (LH) As I use <del> a lot, I use different keys than those proposed by SR.
"
" Set a marker (the cursor is left between the marker characters)
imap <M-Insert> ¡mark!<ESC>i
vmap <M-Insert> ¡mark!
" Jump to next marker
 map <M-Del> ¡jump!
imap <M-Del> ¡jump!


if !exists(":VimrcHelp") 
  command! -nargs=1 VimrcHelp 
endif

:VimrcHelp " 
:VimrcHelp " <M-Insert>   : Inserts a marker                                   [I+V]
:VimrcHelp " <M-Del>      : Jumps to a marker                                  [I+N+V]


" ===========================================================================
" In order to define things like '{'
function! s:Def_Map1(key,expr1,expr2)
  if exists('b:usemarks') && b:usemarks
    return "\<c-r>=MapNoContext('".a:key."',BuildMapSeq('".a:expr2."'))\<cr>"
  else
    return "\<c-r>=MapNoContext('".a:key."', '".a:expr1."')\<cr>"
  endif
endfunction

" s:EscapableBrackets, and s:EscapableBracketsLn are two different functions
" in order : little optimisation
function! s:EscapableBrackets(key, left, right)
  let r = ((getline('.')[col('.')-2] == '\') ? '\\\\' : "") . a:right
  let expr1 = a:left.r.'\<esc\>i'
  let expr2 = a:left.r.'¡mark!\<esc\>F'.a:key.'a'
  if exists('b:usemarks') && b:usemarks
    return "\<c-r>=MapNoContext('".a:key."',BuildMapSeq('".expr2."'))\<cr>"
  else
    return "\<c-r>=MapNoContext('".a:key."', '".expr1."')\<cr>"
  endif
endfunction

function! s:EscapableBracketsLn(key, left, right)
  let r = ((getline('.')[col('.')-2] == '\') ? '\\\\' : "") . a:right
  let expr1 = a:left.'\<cr\>'.r.'\<esc\>O'
  let expr2 = a:left.'\<cr\>'.r.'¡mark!\<esc\>O'
  if exists('b:usemarks') && b:usemarks
    return "\<c-r>=MapNoContext('".a:key."',BuildMapSeq('".expr2."'))\<cr>"
  else
    return "\<c-r>=MapNoContext('".a:key."', '".expr1."')\<cr>"
  endif
endfunction

" ===========================================================================
" If a backslash precede the current cursor position, insert one dollar,
" and two otherwise.
function! Insert_LaTeX_Dollar()
  if getline('.')[col('.')-2] == '\'
    return '$'
  else
    return "\<c-v>$\<c-v>$\<c-r>=Brkt_Mark()\<cr>\<esc>F$i"
  endif
endfunction

" Trick : to be switchable with Triggers.vim
" Calls a custom function or returns <> regarding the options
function! Brkt_lt()
  if exists('b:cb_ltFn')
    return "\<C-R>=" . b:cb_ltFn . "\<CR>"
  else
    return <SID>EscapableBrackets('<', '\<C-V\><', '\<C-V\>>')
  endif
endfunction

" Trick : to be switchable with Triggers.vim
" Calls a custom function, or search for the next '>', or return '>'
" regarding the options.
function! Brkt_gt()
  if exists('b:cb_gtFn')        | return "\<C-R>=" . b:cb_gtFn . "\<CR>"
  elseif exists('b:cb_gtFind')  | return "\<esc>/>/\<cr>a"
  else                          | return ">"
  endif
endfunction

" Centralize all the INSERT-mode mappings associated to quotes
function! Brkt_quote()
  if b:cb_quotes == 2
    if exists("b:usemarks") && b:usemarks == 1
      return "\<c-r>=MapNoContext(\"'\", " .
	\    "\"''\\<C-R\>=Brkt_Mark()\\<CR\>\\<esc\>F'i\")\<cr>"
    else 
      return "\<c-r>=MapNoContext(\"'\", \"''\\<Left\>\")\<cr>"
    endif
  else
    if exists("b:usemarks") && b:usemarks == 1
      return "\<C-V>'\<C-V>'\<c-r>=Brkt_Mark()\<cr>\<ESC>F'i"
    else 
      return "''\<left>"
    endif
  endif
endfunction

" Centralize all the INSERT-mode mappings associated to double-quotes
function! Brkt_Dquote()
  if b:cb_Dquotes == 2
    if exists("b:usemarks") && b:usemarks == 1
      return "\<c-r>=MapNoContext('\"', '" . '\"\"' . "'." . 
       \ '"\\<C-R\>=Brkt_Mark()\\<CR\>\\<esc\>F\\\"i")' . "\<cr>"
    else 
      return "\<c-r>=MapNoContext('\"', '" . 
	\    '\"\"' . "'." . '"\\<Left\>")' . "\<cr>"
    endif
  else
    if exists('b:cb_DqFn')
      return "\<C-R>=" . b:cb_DqFn . "\<CR>"
    elseif exists("b:usemarks") && b:usemarks == 1
      return "\<C-V>\"\<C-V>\"\<c-r>=Brkt_Mark()\<cr>\<ESC>F\"i"
    else 
      return "\"\"\<left>"
    endif
  endif
endfunction

"======================================================================


"======================================================================
" Matching Brackets Macros, From AuCTeX.vim (due to Saul Lubkin).  
" Except, that I use differently the chanching-brackets functions.
" For normal mode.

" Bindings for the Bracket Macros
noremap <M-b>x		:call <SID>DeleteBrackets()<CR>
noremap <M-b><Del>	:call <SID>DeleteBrackets()<CR>
noremap <M-b>(		:call <SID>ChangeRound()<CR>
noremap <M-b>[		:call <SID>ChangeSquare()<CR>
noremap <M-b>{		:call <SID>ChangeCurly()<CR>
noremap <M-b>\		:call <SID>ToggleBackSlash()<CR>

"inoremap <C-Del> :call <SID>DeleteBrackets()<CR>
"inoremap <C-BS> <Left><C-O>:call <SID>DeleteBrackets()<CR>

" Then the procedures.
function! s:DeleteBrackets()
  let s:b = getline(line("."))[col(".") - 2]
  let s:c = getline(line("."))[col(".") - 1]
  if s:b == '\' && (s:c == '{' || s:c == '}')
    normal X%X%
  endif
  if s:c == '{' || s:c == '[' || s:c == '('
    normal %x``x
  elseif s:c == '}' || s:c == ']' || s:c == ')'
    normal %%x``x``
  endif
endfunction

function! s:ChangeCurly()
  let s:c = getline(line("."))[col(".") - 1]
  if s:c == '[' || s:c == '('
    exe "normal! i\<Esc>l%i\<Esc>lr}``r{"
  elseif s:c == ']' || s:c == ')'
    exe "normal! %i\<Esc>l%i\<Esc>lr}``r{%"
  endif
endfunction

function! s:ChangeRound()
  let s:c = getline(line("."))[col(".") - 1]
  if s:c =~ '[\|{'     | normal! %r)``r(
  elseif s:c =~ ']\|}' | normal! %%r)``r(%
  endif
endfunction

function! s:ChangeSquare()
  let s:c = getline(line("."))[col(".") - 1]
  if s:c =~ '(\|{'     | normal! %r]``r[
  elseif s:c =~ ')\|}' | normal! %%r]``r[%
  endif
endfunction

function! s:ToggleBackSlash()
  let s:b = getline(line("."))[col(".") - 2]
  let s:c = getline(line("."))[col(".") - 1]
  if s:b == '\'
    if s:c =~ '(\|{\|['     | normal! %X``X
    elseif s:c =~ ')\|}\|]' | normal! %%X``X%
    endif
  else
    if s:c =~ '(\|{\|['     | exe "normal! %i\\\<esc>``i\\\<esc>"
    elseif s:c =~ ')\|}\|]' | exe "normal! %%i\\\<esc>``i\\\<esc>%"
    endif
  endif
endfunction
 

" ===========================================================================
" Implementation and other remarks :
" (*) Whitin the vnoremaps, `>ll at the end put the cursor at the
"     previously last character of the selected area and slide left twice
"     (ll) to compensate the addition of the sourrounding characters.
" (*) The <M-xxx> key-binding used in insert mode apply on the word
"     currently under the cursor. There also exist the normal mode version
"     of these macros.
"     Unfortunately several of these are not accessible from the french
"     keyboard layout -> <M-{>, <M-[>, <M-`>, etc
" (*) nmap <buffer> " ... is a very bad idea, hence nmap ""
" (*) ¡mark! and ¡jump! can't be called yet from MapNoContext().
"     but <c-r>=Brkt_Mark()<cr> can.
"
" Todo:
" (*) Systematically use b:usemarks for opening and closing
