" ======================================================================
"	Stephen Riehm's braketing macros for vim
"	Customizations by Luc Hermitte	<hermitte {at} free {dot} fr>
"
"URL: http://hermitte.free.fr/vim/ressources/vimfiles/plugin/bracketing.base.vim
" ======================================================================
" History:	{{{1
"	Last Update: 08th nov 2002
"		* Pure vim6 solution.
"		* s/brkt/marker in options and functions names.
"		* Support closing markers of several characters.
"		* New mapping to jump to the previous marker
"		* Two commands: :MN and :MP that work in normal, visual and
"		  insert modes and permit to jump to next/previous marker.
"	Last Update: 21st jul 2002	by LH
"		* e-mail address obfuscated for spammers
"	Last Update: 04th apr 2002	by LH
"		* Marker_Txt takes an optional parameter : the text
"	Last Update: 21st feb 2002	by LH
"		* When a comment is within a mark, we now have the possibility to
"		* select the mark (in Select-MODE ...) instead of echoing the
"		comment.
"		* In this mode, an empty mark can be chosen or deleted.
"	Previous Version: ??????	by LH
"		* Use accessors to acces b:marker_open and b:marker_close. 
"		  Reason: Changing buffers with VIM6 does not re-source this
"		  file.
"	Previous Version: 22nd sep 2001	by LH
"		* Delete all the settings that should depends on ftplugins
"		* Enable to use other markers set as a buffer-relative option.
"	Based On Version: 16.01.2000
"		(C)opyleft: Stephen Riehm 1991 - 2000
"
"	Needs: 	* VIM 6.0 +
"		* misc_map.vim	(MapAroundVisualLines, by LH)
"
"	Credits:
"		Stephen Riehm, Benji Fisher, Gergely Kontra, Robert Kelly IV.
"
"------------------------------------------------------------------------
" Options:	{{{1
" b:marker_open		-> the characters that opens the marker  ; default '«'
" b:marker_close	-> the characters that closes the marker ; default '»'
" 	They are buffer-relative in order to be assigned to different values
" 	regarding the filetype of the current buffer ; e.g. '«»' is not an
" 	appropriate marker with LaTeX files.
"
" g:marker_prefers_select					; default 1
" 	Option to determine if the comment within a marker should be echoed or
" 	if the whole marker should be selected (select-mode).
" 	Beware: The select-mode is considered to be a visual-mode. Hence all
" 	the i*map won't expand in select-mode! i*abbr fortunately does.
" 	
" g:marker_select_empty_marks					; default 1
" 	Option to determine if an empty marker should be selected or deleted.
" 	Works only if g:marker_prefers_select is set.
"
"------------------------------------------------------------------------
" }}}1
" ===========================================================================
" Settings	{{{1
" ========
"	These settings are required for the macros to work.
"	Essentially all you need is to tell vim not to be vi compatible,
"	and to do some kind of groovy autoindenting.
"
"	Tell vim not to do screwy things when searching
"	(This is the default value, without c)
"set cpoptions=BeFs
set cpoptions-=c
" Avoid reinclusion
if exists("g:loaded_bracketing_base") | finish | endif
let g:loaded_bracketing_base = 1

let s:cpo_save = &cpo
set cpo&vim

" Mappings that can be redefined {{{1
" ==============================
" (LH) As I use <del> a lot, I use different keys than those proposed by SR.
"
if !hasmapto('<Plug>¡mark!', 'v') && (mapcheck("<M-Insert>", "v") == "")
  vmap <unique> <M-Insert> <Plug>¡mark!
endif
if !hasmapto('<Plug>¡mark!<ESC>i', 'i') && (mapcheck("<M-Insert>", "i") == "")
  imap <unique> <M-Insert> <Plug>¡mark!
endif
if !hasmapto('<Plug>¡jump!', 'i') && (mapcheck("<M-Del>", "i") == "")
  imap <unique> <M-Del> <Plug>¡jump!
endif
if !hasmapto('<Plug>¡jump!') && (mapcheck("<M-Del>") == "")
  map <unique> <M-Del> <Plug>¡jump!
endif
if !hasmapto('<Plug>¡jumpB!', 'i') && (mapcheck("<M-S-Del>", "i") == "")
  imap <unique> <M-S-Del> <Plug>¡jumpB!
endif
if !hasmapto('<Plug>¡jumpB!') && (mapcheck("<M-S-Del>") == "")
  map <unique> <M-S-Del> <Plug>¡jumpB!
endif

imap <Plug>¡mark!  ¡mark!<C-R>=<sid>MoveWithinMarker()<cr>
vmap <Plug>¡mark!  ¡mark!
 map <Plug>¡jump!  ¡jump!
imap <Plug>¡jump!  ¡jump!
 map <Plug>¡jumpB! ¡jumpB!
imap <Plug>¡jumpB! ¡jumpB!
" Note: don't add "<script>" within the four previous <Plug>-mappings or else
" they won't work anymore.
" }}}

" Commands {{{1
" ========
:command! -nargs=0 -range MP exe ":normal <Plug>¡jumpB!"
:command! -nargs=0 -range MN exe ":normal <Plug>¡jump!"
:command! -nargs=* -range MI :call s:MarkerInsert(<q-args>)
" :command! -nargs=0 MN <Plug>¡jump!
" :command! -nargs=0 MI <Plug>¡mark!

" This test function is incapable of detecting the current mode.
" There is no way to know we are in insert mode.
" There is no way to know if we are in visual mode or if we are in normal mode
" and the cursor is on the start of the previous visual region.
function! s:MarkerInsert(text) range
  let mode =  confirm("'< = (".line("'<").','.virtcol("'<").
	\ ")\n'> =(".line("'>").','.virtcol("'>"). 
	\ ")\n.  =(".line(".").','.virtcol("."). ")\n\n Mode ?",
	\ "&Visual\n&Normal\n&Insert", 1)
  if mode == 1
    normal gv¡mark!
  elseif mode == 2
    normal viw¡mark!
  elseif mode == 3
    "<c-o>:MI titi toto<cr>
    let text = Marker_Txt(a:text)
    exe "normal! i".text."\<esc>l"
  endif
endfunction

" }}}1

" Jump to next marker {{{1
" ===================
" Rem: 
" * two working modes : display the text between the markers or select it
" * &wrapscan is implicitly taken into acount
" * The use of the SELECT-mode is inspired by 
"   Gergely Kontra <kgergely at mcl.hu>
" * The backward search of markers is due to by Robert Kelly IV.
"	
function! Marker_Jump(...) " {{{2
  " ¿ forward([1]) or backward(0) ?
  let direction = ((a:0 > 0) && (a:1=='1')) ? '' : 'b'

  " if within a marker, and going backward, {{{3
  let position = line('.') . "normal! ".virtcol('.').'|'
  if direction == 'b'
    " then: go to the start of the marker.
    " Principle: {{{
    " 1- search backward the pair {open, close}
    "    In order to find the current pair correctly, we must consider the
    "    beginning of the match (\zs) to be just before the last character of
    "    the second pair.
    " 2- Then, in order to be sure we did jump to a match of the open marker,
    "    we search forward for its closing counter-part.
    "    Test: with open='«', close = 'ééé', and the text:{{{
    "       blah «»
    "       «1ééé  «2ééé
    "       «3ééé foo
    "       «4ééé
    "    with the cursor on any character. }}}
    "    Without this second test, the cursor would have been moved to the end
    "    of "blah «" which is not the beginning of a marker. 
    " }}}
    if searchpair(Marker_Open(), '', substitute(Marker_Close(), '.$', '\\zs\0', ''), 'b')
      if ! searchpair(Marker_Open(), '', Marker_Close(), 'n')
	" restore cursor position as we are not within a marker.
	exe position
      endif
    endif
  endif
  " }}}3
  " "&ws?'w':'W'" is useless with search()
  if !search(Marker_Open() .'.\{-}'. Marker_Close(), direction) " {{{3
    " Case:		No more marker
    " Traitment:	None
    return ""
  else " found! {{{3
    if s:Select_or_Echo() " select! {{{4
      " let select = "v/".Marker_Close()."/e\<cr>"
      let select = 'v¡mark_close!'
      if s:Select_Empty_Mark() || (getline('.')[col('.')]!=Marker_Close())
	" Case:		Marker containing a tag, e.g.: «tag»
	" Traitment:	The marker is selected, going into SELECT-mode
	return select."\<c-g>"
	" return "vf".Marker_Close()."\<c-g>"
      else
	" Case:		Empty marker, i.e. not containing a tag, e.g.: «»
	" Traitment:	The marker is deleted, going into INSERT-mode.
	return select."c"
	" return "vf".Marker_Close()."c"
      endif
    else " Echo! {{{4
      " Case:		g:marker_prefers_select == 0
      " Traitment:	Echo the tag within the marker
      let lig = "a:\<c-v>\"\<esc>h\"my/".Marker_Close() . "/\<cr>"
      let lig = lig . "h@m\<cr>¡Cmark_close!"
      return lig
    endif
  endif
endfunction " }}}2

" Thanks to this trick, we can silently select with "v/pattern/e<cr>"
vnoremap <silent> ¡mark_close! /<c-r>=Marker_Close()<cr>/e<cr>
" onoremap <silent> ¡mark_close! /<c-r>=Marker_Close()<cr>/e<cr>
nnoremap <silent> ¡Cmark_close! c/<c-r>=Marker_Close()<cr>/e<cr>
" ------------------------------------------------------------------------
" Internals {{{1
" Accessors to markers definition:
function! Marker_Open()
  if !exists("b:marker_open") | let b:marker_open = '«' | endif
  return b:marker_open
endfunction

function! Marker_Close()
  if !exists("b:marker_close") | let b:marker_close = '»' | endif
  return b:marker_close
endfunction

function! Marker_Txt(...)
  return Marker_Open() . ((a:0>0) ? a:1 : '') . Marker_Close()
endfunction

function! s:MoveWithinMarker()
  " Here, b:marker_close exists
  return "\<esc>" . strlen(b:marker_close) . 'ha'
endfunction

" Other option :
" b:usemarks

function! s:Select_or_Echo()
  return exists("g:marker_prefers_select") ? g:marker_prefers_select : 1
endfunction

function! s:Select_Empty_Mark() " or delete them ?
  return exists("g:marker_select_empty_marks") ? g:marker_select_empty_marks : 1
endfunction

" Internal mappings {{{1
" =================
" Defines: ¡mark! and ¡jump!

" Set a marker ; contrary to <Plug>¡mark!, ¡mark! doesn't move the cursor
" between the marker characters.
inoremap <silent> ¡mark! <c-r>=Marker_Txt()<cr>
vnoremap <silent> ¡mark! 
      \ :call MapAroundVisualLines(Marker_Open(),Marker_Close(),0,0)<cr>
"Old: imap ¡mark! <C-V>«<C-V>»
"Old: vmap ¡mark! "zc<C-V>«<C-R>z<C-V>»<ESC>

" <c-l> should used to unselect the previous mark (not changed), when we move
" to another line. To be exploitable, <esc> has been moved out of the function!
vnoremap <silent> ¡jump! <ESC><c-l>@=Marker_Jump(1)<cr>
nnoremap <silent> ¡jump! @=Marker_Jump(1)<cr>
    imap <silent> ¡jump! <ESC>¡jump!
vnoremap <silent> ¡jumpB! <ESC><c-l>@=Marker_Jump(0)<cr>
nnoremap <silent> ¡jumpB! @=Marker_Jump(0)<cr>
    imap <silent> ¡jumpB! <ESC>¡jumpB!
"Old: map ¡jump! /«.\{-}»/<C-M>a:"<ESC>h"myt»h@m<C-M>cf»

" Help stuff {{{1
if !exists(":VimrcHelp") 
  command! -nargs=1 VimrcHelp 
endif

:VimrcHelp " 
:VimrcHelp " <M-Insert>   : Inserts a marker                                   [I+V]
:VimrcHelp " <M-Del>      : Jumps to a marker                                  [I+N+V]
" }}}1
" ============================================================================
" Stephen Riehm's Bracketing macros {{{1
" ========== You should not need to change anything below this line ==========
"

"
"	Quoting/bracketting macros
"	Note: The z cut-buffer is used to temporarily store data!
"
"	double quotes
imap ¡"! <C-V>"<C-V>"¡mark!<ESC>F"i
vmap ¡"! "zc"<C-R>z"<ESC>
"	single quotes
imap ¡'! <C-V>'<C-V>'¡mark!<ESC>F'i
vmap ¡'! "zc'<C-R>z'<ESC>
"	stars
imap ¡*! <C-V>*<C-V>*¡mark!<ESC>F*i
vmap ¡*! "zc*<C-R>z*<ESC>
"	braces
imap ¡(! <C-V>(<C-V>)¡mark!<ESC>F)i
vmap ¡(! "zc(<C-R>z)<ESC>
"	braces - with padding
imap ¡)! <C-V>(  <C-V>)¡mark!<ESC>F i
vmap ¡)! "zc( <C-R>z )<ESC>
"	underlines
imap ¡_! <C-V>_<C-V>_¡mark!<ESC>F_i
vmap ¡_! "zc_<C-R>z_<ESC>
"	angle-brackets
imap ¡<! <C-V><<C-V>>¡mark!<ESC>F>i
vmap ¡<! "zc<<C-R>z><ESC>
"	angle-brackets with padding
imap ¡>! <C-V><  <C-V>>¡mark!<ESC>F i
vmap ¡>! "zc< <C-R>z ><ESC>
"	square brackets
imap ¡[! <C-V>[<C-V>]¡mark!<ESC>F]i
vmap ¡[! "zc[<C-R>z]<ESC>
"	square brackets with padding
imap ¡]! <C-V>[  <C-V>]¡mark!<ESC>F i
vmap ¡]! "zc[ <C-R>z ]<ESC>
"	back-quotes
imap ¡`! <C-V>`<C-V>`¡mark!<ESC>F`i
vmap ¡`! "zc`<C-R>z`<ESC>
"	curlie brackets
imap ¡{! <C-V>{<C-V>}¡mark!<ESC>F}i
vmap ¡{! "zc{<C-R>z}<ESC>
"	new block bound by curlie brackets
imap ¡}! <ESC>o{<C-M>¡mark!<ESC>o}¡mark!<ESC>^%¡jump!
vmap ¡}! >'<O{<ESC>'>o}<ESC>^
"	spaces :-)
imap ¡space! .  ¡mark!<ESC>F.xa
vmap ¡space! "zc <C-R>z <ESC>
"	Nroff bold
imap ¡nroffb! \fB\fP¡mark!<ESC>F\i
vmap ¡nroffb! "zc\fB<C-R>z\fP<ESC>
"	Nroff italic
imap ¡nroffi! \fI\fP¡mark!<ESC>F\i
vmap ¡nroffi! "zc\fI<C-R>z\fP<ESC>

"
" Extended / Combined macros
"	mostly of use to programmers only
"
"	typical function call
imap ¡();!  <C-V>(<C-V>);¡mark!<ESC>F)i
imap ¡(+);! <C-V>(  <C-V>);¡mark!<ESC>F i
"	variables
imap ¡$! $¡{!
vmap ¡$! "zc${<C-R>z}<ESC>
"	function definition
imap ¡func! ¡)!¡mark!¡jump!¡}!¡mark!<ESC>kk0¡jump!
vmap ¡func! ¡}!'<kO¡)!¡mark!¡jump!<ESC>I

"
" Special additions:
"
"	indent mail
vmap ¡mail! :s/^[^ <TAB>]*$/> &/<C-M>
map  ¡mail! :%s/^[^ <TAB>]*$/> &/<C-M>
"	comment marked lines
imap ¡#comment! <ESC>0i# <ESC>A
vmap ¡#comment! :s/^/# /<C-M>
map  ¡#comment! :s/^/# /<C-M>j
imap ¡/comment! <ESC>0i// <ESC>A
vmap ¡/comment! :s,^,// ,<C-M>
map  ¡/comment! :s,^,// ,<C-M>j
imap ¡*comment! <ESC>0i/* <ESC>A<TAB>*/<ESC>F<TAB>i
vmap ¡*comment! :s,.*,/* &	*/,<C-M>
map  ¡*comment! :s,.*,/* &	*/,<C-M>j
"	uncomment marked lines (strip first few chars)
"	doesn't work for /* comments */
vmap ¡stripcomment! :s,^[ <TAB>]*[#>/]\+[ <TAB>]\=,,<C-M>
map  ¡stripcomment! :s,^[ <TAB>]*[#>/]\+[ <TAB>]\=,,<C-M>j

"
" HTML Macros
" ===========
"
"	turn the current word into a HTML tag pair, ie b -> <b></b>
imap ¡Htag! <ESC>"zyiwciw<<C-R>z></<C-R>z>¡mark!<ESC>F<i
vmap ¡Htag! "zc<¡mark!><C-R>z</¡mark!><ESC>`<¡jump!
"
"	set up a HREF
imap ¡Href! <a href="¡mark!">¡mark!</a>¡mark!<ESC>`[¡jump!
vmap ¡Href! "zc<a href="¡mark!"><C-R>z</a>¡mark!<ESC>`<¡jump!
"
"	set up a HREF name (tag)
imap ¡Hname! <a name="¡mark!">¡mark!</a>¡mark!<ESC>`[¡jump!
vmap ¡Hname! "zc<a name="¡mark!"><C-R>z</a>¡mark!<ESC>`<¡jump!

" }}}1
" ======================================================================
let &cpo = s:cpo_save
" vim600: set fdm=marker:
