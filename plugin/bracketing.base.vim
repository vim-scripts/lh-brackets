"------------------------------------------------------------------------
"	Stephen Riehm's braketing macros for vim
"	Customizations by Luc Hermitte	<hermitte@free.fr>
"
"------------------------------------------------------------------------
" Options:
" b:brkt_open		-> the character that opens the marker  ; default '«'
" b:brkt_close		-> the character that closes the marker ; default '»'
" 	They are buffer-relative in order to be assigned to different values
" 	regarding the filetype of the current buffer ; e.g. '«»' is not an
" 	appropriate marker with LaTeX files.
"
" g:brkt_prefers_select						; default 1
" 	Option to determine if the comment within a marker should be echoed or
" 	if the whole marker should be selected (select-mode).
" 	Beware: The select-mode is considered to be a visual-mode. Hence all
" 	the i*map won't expand in select-mode!
" 	
" g:brkt_select_empty_marks					; default 1
" 	Option to determine if an empty marker should be selected or deleted.
" 	Works only if g:brkt_prefers_select is set.
"
"------------------------------------------------------------------------
" History:
"	Last Update: 04th apr 2002	by LH
"		Brkt_Mark takes an optional parameter : the text
"	Last Update: 21st feb 2002	by LH
"		When a comment is within a mark, we now have the possibility to
"		select the mark (in Select-MODE ...) instead of echoing the
"		comment.
"		In this mode, an empty mark can be chosen or deleted.
"	Previous Version: ??????	by LH
"		Use accessors to acces b:brkt_open and b:brkt_close. 
"		Reason: Changing buffers with VIM6 does not resource this
"		file.
"	Previous Version: 22nd sep 2001	by LH
"		Delete all the settings that should depends on ftplugins
"		Enable to use other markers set as a buffer-relative option.
"	Based On Version: 16.01.2000
"	(C)opyleft: Stephen Riehm 1991 - 2000
"
"	Needs: misc_map.vim	(MapAroundVisualLines, by LH)
"
" ===========================================================================
version 5.7

"	you MAY want to change some settings, or the characters used for the
"	jump marks - if so, make your changes here

" Settings
" ========
"
"	These settings are required for the macros to work.
"	Essentially all you need is to tell vim not to be vi compatible,
"	and to do some kind of groovy autoindenting.
"
"	Tell vim not to do screwy things when searching
"	(This is the default value, without c)
"set cpoptions=BeFs
set cpoptions-=c

" Avoid reinclusion
if !exists("g:bracketing_base")
  let g:bracketing_base = 1


" Jump point macros
" =================
"
"	set a marker (the cursor is left between the marker characters)
"	This is the place to change the jump marks if you want to
"
inoremap ¡mark! <c-r>=Brkt_Mark()<cr>
vnoremap ¡mark! :call MapAroundVisualLines(Brkt_Open(),Brkt_Close(),0,0)<cr>
"imap ¡mark! <C-V>«<C-V>»
"vmap ¡mark! "zc<C-V>«<C-R>z<C-V>»<ESC>
"

" Jump to next marker
" ===================
"
" Rem: 
" * two working modes : display the text between the markers or select it
" * &Wrapscan is taken into acount
" * This new version using select was inspired by 
"   Gergely Kontra <kgergely@mcl.hu>
"	
function! Brkt_Jump()
  if Select_or_Echo()
    if !search(Brkt_Open() .'.\{-}'. Brkt_Close(), &ws?'w':'W') "No more marks
      return ""
      "      return "\<cr>"
    else 
      if Select_Empty_Mark() || (getline('.')[col('.')]!=Brkt_Close())
	return "vf".Brkt_Close()."\<c-g>"
"	return "\<esc>vf".Brkt_Close()."\<c-g>"
      else
	return "vf".Brkt_Close()."c"
"	return "\<esc>vf".Brkt_Close()."c"
      endif
    endif
  else
    "let lig = '/' .Brkt_Open() . '[^'. Brkt_Open() .']\{-}' .Brkt_Close() .'/'
    let lig = '/' . Brkt_Open() . '.\{-}' . Brkt_Close() . '/'
    let lig = lig . "\<cr>a:\<c-v>\"\<esc>h\"myt".Brkt_Close()
    let lig = lig . "h@m\<cr>cf" . Brkt_Close() 
    return lig
  endif
endfunction

"map ¡jump! /«.\{-}»/<C-M>a:"<ESC>h"myt»h@m<C-M>cf»

" <c-l> should used to unselect the previous mark (not changed), when we move
" to another line. To be exploitable, <esc> has been moved out of the function!
vnoremap <silent> ¡jump! <ESC><c-l>@=Brkt_Jump()<cr>
nnoremap <silent> ¡jump! @=Brkt_Jump()<cr>
    imap <silent> ¡jump! <ESC>¡jump!

" ------------------------------------------------------------------------
" Accessors to options
function! Brkt_Open()
  if !exists("b:brkt_open") | let b:brkt_open = '«' | endif
  return b:brkt_open
endfunction

function! Brkt_Close()
  if !exists("b:brkt_close") | let b:brkt_close = '»' | endif
  return b:brkt_close
endfunction

" other option :
" b:usemarks

function! Brkt_Mark(...)
  return Brkt_Open() . ((a:0>0) ? a:1 : '') . Brkt_Close()
endfunction

function! Select_or_Echo()
  return exists("g:brkt_prefers_select") ? g:brkt_prefers_select : 1
endfunction

function! Select_Empty_Mark() " or delete them ?
  return exists("g:brkt_select_empty_marks") ? g:brkt_select_empty_marks : 1
endfunction

" ============================================================================
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

" avoir reinclusion
endif
