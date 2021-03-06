" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/changesPlugin.vim	[[[1
73
" ChangesPlugin.vim - Using Signs for indicating changed lines
" ---------------------------------------------------------------
" Version:  0.14
" Authors:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 14 Aug 2013 22:10:39 +0200


" Script:  http://www.vim.org/scripts/script.php?script_id=3052
" License: VIM License
" Documentation: see :help changesPlugin.txt
" GetLatestVimScripts: 3052 14 :AutoInstall: ChangesPlugin.vim


" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_changes")
 finish
endif
let g:loaded_changes       = 1
let s:keepcpo              = &cpo
set cpo&vim

let s:autocmd  = get(g:, 'changes_autocmd', 0)
" ------------------------------------------------------------------------------
" Public Interface: {{{1

" Define the Shortcuts:
com! -nargs=? -complete=file -bang EC	 EnableChanges<bang> <args>
com! DC	 DisableChanges
com! TCV ToggleChangeView
com! CC  ChangesCaption
com! CL  ChangesLinesOverview
com! CD  ChangesDiffMode

com! -nargs=? -complete=file -bang EnableChanges	call changes#EnableChanges(1, <q-bang>, <q-args>)
com! DisableChanges		call changes#CleanUp()
com! ToggleChangeView		call changes#TCV()
com! ChangesCaption		call changes#Output(1)
com! ChangesLinesOverview	call changes#EnableChanges(2, '')
com! ChangesDiffMode		call changes#EnableChanges(3, '')

if s:autocmd
    exe "try | call changes#Init() | catch | call changes#WarningMsg() | endtry"
    exe "au BufWinEnter,BufWritePost * call changes#EnableChanges(1, '')"
endif

au VimEnter * let g:changes_did_startup = 1

" Mappings:  "{{{1
if !hasmapto("[h")
    map <expr> <silent> [h changes#MoveToNextChange(0, v:count1)
endif
if !hasmapto("]h")
    map <expr> <silent> ]h changes#MoveToNextChange(1, v:count1)
endif

" Text-object: A hunk
if !hasmapto("ah", 'v')
    vmap <expr> <silent> ah changes#CurrentHunk()
endif

if !hasmapto("ah", 'o')
    omap <silent> ah :norm Vah<cr>
endif
    
" =====================================================================
" Restoration And Modelines: {{{1
" vim: fdm=marker
let &cpo= s:keepcpo
unlet s:keepcpo

" Modeline
" vi:fdm=marker fdl=0
autoload/changes.vim	[[[1
954
" Changes.vim - Using Signs for indicating changed lines
" ---------------------------------------------------------------
" Version:  0.14
" Authors:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 14 Aug 2013 22:10:39 +0200
" Script:  http://www.vim.org/scripts/script.php?script_id=3052
" License: VIM License
" Documentation: see :help changesPlugin.txt
" GetLatestVimScripts: 3052 14 :AutoInstall: ChangesPlugin.vim

" Documentation: "{{{1
" See :h ChangesPlugin.txt

" Check preconditions
fu! s:Check() "{{{1
    " Check for the existence of unsilent
    if exists(":unsilent")
	let s:echo_cmd='unsilent echo'
    else
	let s:echo_cmd='echo'
    endif

    if !has("diff")
	call add(s:msg,"Diff support not available in your Vim version.")
	call add(s:msg,"changes plugin will not be working!")
	throw 'changes:abort'
    endif

    if  !has("signs")
	call add(s:msg,"Sign Support support not available in your Vim version.")
	call add(s:msg,"changes plugin will not be working!")
	throw 'changes:abort'
    endif

    if !executable("diff") || executable("diff") == -1
	call add(s:msg,"No diff executable found")
	call add(s:msg,"changes plugin will not be working!")
	throw 'changes:abort'
    endif

    " This variable is a prefix for all placed signs.
    " This is needed, to not mess with signs placed by the user
    let s:sign_prefix = 99
    let s:ids={}
    let s:ids["add"]   = hlID("DiffAdd")
    let s:ids["del"]   = hlID("DiffDelete")
    let s:ids["ch"]    = hlID("DiffChange")
    let s:ids["ch2"]   = hlID("DiffText")

    call s:DefineSigns()
endfu

fu! s:AuCmd(arg) "{{{1
    if a:arg
	augroup Changes
	    autocmd!
	    let s:verbose=0
	    au InsertLeave,CursorHold,BufWritePost * :call s:UpdateView()
	augroup END
    else
	augroup Changes
	    autocmd!
	augroup END
	augroup! Changes
    endif
endfu

fu! s:DefineSigns() "{{{1
    if !empty(s:DefinedSignsNotExists())
	for key in keys(s:signs)
	    exe "silent sign undefine " key
	endfor
    endif
    for key in keys(s:signs)
	exe "sign define" key s:signs[key]
    endfor
endfu

fu! s:CheckLines(arg) "{{{1
    " OLD: not needed any more.
    " a:arg  1: check original buffer
    "        0: check diffed scratch buffer
    let line=1
    " This should not be necessary, since b:diffhl for the scratch buffer
    " should never be accessed. But just to be sure, we define it here
"    if (!a:arg) && !exists("b:diffhl")
"	let b:diffhl = {'del': []}
"    endif
    while line <= line('$')
	let id=diff_hlID(line,1)
	if  (id == 0)
	    let line+=1
	    continue
	" in the original buffer, there won't be any lines accessible
	" that have been 'marked' deleted, so we need to check scratch
	" buffer for added lines
	elseif (id == s:ids['add']) && !a:arg
	    let s:temp['del']   = s:temp['del'] + [ line ]
	elseif (id == s:ids['add']) && a:arg
	    let b:diffhl['add'] = b:diffhl['add'] + [ line ]
	elseif ((id == s:ids['ch']) || (id == s:ids['ch2']))  && a:arg
	    let b:diffhl['ch']  = b:diffhl['ch'] + [ line ]
	endif
	let line+=1
    endw
endfu

fu! s:UpdateView() "{{{1
    if !exists("b:changes_chg_tick")
	let b:changes_chg_tick = 0
    endif
    " Only update, if there have been changes to the buffer
    if  b:changes_chg_tick != b:changedtick
	" Turn off displaying the Caption
	let s:verbose=0
	call s:GetDiff(1, '')
	let b:changes_chg_tick = b:changedtick
    endif
endfu

fu! s:PlaceSignDummy(place) "{{{1
    " could be called, without init calling first, so thta s:sign_prefix might
    " not be defined yet. In that case, there can't be a dummy being defined
    " yet!
    if !exists("s:sign_prefix")
	return
    endif
    if a:place
	if empty(s:DefinedSignsNotExists())
	    call s:DefineSigns()
	endif
	let b = copy(s:placed_signs[0])
	if !empty(b)
	    " only place signs, if signs have been defined
	    exe "sign place " s:sign_prefix.'0 line=1 name=dummy buffer='. bufnr('')
	endif
    else
	exe "sign unplace " s:sign_prefix.'0'
    endif
endfu

fu! s:DefinedSignsNotExists() "{{{1
    if !exists("s:sign_definition")
	redir => a|exe "sil sign list"|redir end
	let s:sign_definition = split(a, "\n")
    endif
    let pat = join(map(keys(s:signs),'"^sign ".v:val'), '\|')
    let b = filter(copy(s:sign_definition), 'v:val =~ pat')
    return b
endfu

fu! s:PlaceSigns(dict) "{{{1
    if empty(s:DefinedSignsNotExists())
	call s:DefineSigns()
    endif
    let b = copy(s:placed_signs[1])
    let b = map(b, 'matchstr(v:val, ''line=\zs\d\+'')')
    for [ id, lines ] in items(a:dict)
	for item in lines
	    " One special case could occur:
	    " You could delete the last lines. In that case, we couldn't place
	    " here the deletion marks. If this happens, place the deletion
	    " marks on the last line
	    if item > line('$')
		let item=line('$')
	    endif
	    " There already exists a sign in this line, we might skip placing
	    " a sign here  
	    if index(b, string(item)) > -1 &&
	    \  get(g:, 'changes_respect_other_signs', 0)
		continue
	    endif
	    exe "sil sign place " s:sign_prefix . item . " line=" . item .
		\ " name=" . id . " buffer=" . bufnr('')
	endfor
    endfor
endfu

fu! s:UnPlaceSigns(force) "{{{1
    if !exists("s:sign_prefix")
	return
    endif
    let b = s:PlacedSigns()[0]
    let b=map(b, 'matchstr(v:val, ''id=\zs\d\+'')')
    for id in sort(b)
	if id == s:sign_prefix.'0' && !a:force
	    " Keep dummy, so the sign column does not vanish
	    continue
	endif
	exe "sign unplace" id
    endfor
endfu

fu! s:Cwd() "{{{1
    return escape(getcwd(), ' ')
endfu

fu! s:Writefile(name) "{{{1
    let a = getline(1,'$')
    if &ff ==? 'dos'
	" TODO: What about mac format?
	call map(a, 'v:val.nr2char(13)')
    endif
    if writefile(a + [''], a:name, 'b') == -1
	throw "changes:abort"
    endif
endfu

fu! s:PreviewDiff(file) "{{{1
    try
	if	!exists('g:changes_did_startup') || !get(g:, 'changes_diff_preview', 0)
		    \ || &diff
	    return
	endif
	let bufcontent = readfile(a:file)
	if len(bufcontent) > 2
	    let bufcontent[0] = substitute(bufcontent[0], s:diff_in_old, expand("%"), '')
	    let bufcontent[1] = substitute(bufcontent[1], s:diff_in_cur, expand("%")." (cur)", '')
	    call writefile(bufcontent, a:file)
	endif

	let bufnr = bufnr('')
	let cur = exists("b:current_line") ? b:current_line : 0
	if cur
	    exe printf(':noa sil! pedit +/@@\ -%d.*\\n\\zs %s', cur, a:file)
	    call setbufvar(a:file, "&ft", "diff")
	    call setbufvar(a:file, '&bt', 'nofile')
	    exe "noa" bufwinnr(bufnr)."wincmd w"
	else
	    sil! pclose
	endif
    catch
    endtry
endfu
fu! s:MakeDiff_new(file) "{{{1
    " Parse Diff output and place signs
    " Needs unified diff output
    try
	let _pwd = s:ChangeDir()
	unlet! b:current_line
	call s:Writefile(s:diff_in_cur)
	" exe ":sil noa :w" s:diff_in_cur
	if !s:vcs || !empty(a:file)
	    let file = !empty(a:file) ? a:file : bufname('')
	    if empty(file)
		throw "changes:abort"
	    endif
	    if !s:Is('unix')
		let output = system("copy ". shellescape(file). " ". s:diff_in_old)
	    else
		let output = system("cp -- ". shellescape(file). " ". s:diff_in_old)
	    endif
	    if v:shell_error
		call add(s:msg, output[:-2])
		throw "changes:abort"
	    endif
	    "exe ':sil !diff -u '.  shellescape(bufname(''),1). ' '. s:diff_in_cur. '>' s:diff_out
	else
	    if b:vcs_type == 'git'
		let git_rep_p = s:ReturnGitRepPath()
		if !empty(git_rep_p)
		    exe 'lcd' git_rep_p
		endif
	    elseif b:vcs_type == 'cvs'
		" I am not sure, if this is the best way
		" to query CVS. But just to make sure, 
		" we are in the right path and we don't have
		" to consider CVSROOT
		exe 'lcd' fnamemodify(expand('%'), ':p:h')
	    endif
	    let cmd = printf("%s %s%s > %s", (b:vcs_type==?'rcs'?'':b:vcs_type),
			\ s:vcs_cat[b:vcs_type], shellescape(expand('%')),
			\ s:diff_in_old)
	    let output = system(cmd)
	    if v:shell_error
		call add(s:msg, output[:-2])
		throw "changes:abort"
	    endif
	endif
	let cmd = printf("diff -a -U0 -N %s %s > %s", 
	    \ s:diff_in_old, s:diff_in_cur, s:diff_out)
	let output = system(cmd)
	if v:shell_error >= 2 || v:shell_error < 0
	    " diff returns 2 on errors
	    call add(s:msg, output[:-2])
	    throw "changes:abort"
	endif
	if getfsize(s:diff_out) == 0
	    call add(s:msg,"No differences found!")
	    return
	endif
	call s:ParseDiffOutput(s:diff_out)
    finally
	call s:PreviewDiff(s:diff_out)
	for file in [s:diff_in_cur, s:diff_in_old, s:diff_out]
	    call delete(file)
	endfor
	exe 'lcd' _pwd
    endtry
endfu

fu! s:ChangeDir()
    let _pwd = s:Cwd()
    exe "lcd " fnameescape(fnamemodify(expand("%"), ':h'))
    return _pwd
endfu


fu! s:MakeDiff(...) "{{{1
    " Old version, only needed, when GetDiff(3) is called (or argument 1 is
    " non-empty)
    " Get diff for current buffer with original
    let o_pwd = s:ChangeDir()
    let bnr = bufnr('%')
    let ft  = &l:ft
    noa vert new
    set bt=nofile
    let scratchbuf = bufnr('')
    if !s:vcs
	exe ":silent :r " (exists("a:1") && !empty(a:1) ? a:1 : '#')
	let &l:ft=ft
    else
	let vcs=getbufvar(bnr, 'vcs_type')
	try
	    if vcs == 'git'
		let git_rep_p = s:ReturnGitRepPath()
		if !empty(git_rep_p)
		    exe 'lcd' git_rep_p
		endif
	    elseif vcs == 'cvs'
		" I am not sure, if this is the best way
		" to query CVS. But just to make sure, 
		" we are in the right path and we don't have
		" to consider CVSROOT
		exe 'lcd' fnamemodify(expand('#'), ':p:h')
	    endif
	    let output = system((vcs==?'rcs'?'':vcs) . ' '. s:vcs_cat[vcs] .  expand("#") . '>'.  s:diff_out)
	    if v:shell_error
		call add(s:msg, output[:-2])
		throw "changes:abort"
	    endif
	    let fsize=getfsize(s:diff_out)
	    if fsize == 0
		call delete(s:diff_out)
		call add(s:msg,"Couldn't get VCS output, aborting")
		"call s:MoveToPrevWindow()
		exe "noa" bufwinnr(bnr) "wincmd w"
		throw "changes:abort"
	    endif
	    exe ':silent :r' s:diff_out
        catch /^changes: No git Repository found/
	    call add(s:msg,"Unable to find git Top level repository.")
	    echo v:errmsg
	    exe "noa" bufwinnr(bnr) "wincmd w"
	    throw "changes:abort"
	catch
	    if bufnr('%') != bnr
		"call s:MoveToPrevWindow()
		exe "noa" bufwinnr(bnr) "wincmd w"
	    endif
	    throw "changes:abort"
	finally
	    call delete(s:diff_out)
	endtry
    endif
    0d_
    diffthis
    exe "noa" bufwinnr(bnr) "wincmd w"
    diffthis
    exe "lcd "  o_pwd
    return scratchbuf
endfu

fu! s:ParseDiffOutput(file) "{{{1
    let b:current_line = 1000000 
    for line in filter(readfile(a:file), 'v:val=~''^@@''')
	let submatch = matchlist(line, '@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@')

	if empty(submatch)
	    " There was probably an error, skip parsing now
	    return
	else
	    let old_line = submatch[1] + 0
	    let old_count = (empty(submatch[2]) ? 1 : submatch[2]) + 0
	    let new_line = submatch[3] + 0
	    let new_count = (empty(submatch[4]) ? 1 : submatch[4]) + 0
	    if b:current_line > (old_line - line('.'))
		let b:current_line = old_line
	    endif
	endif

	" Line added
	if old_count == 0 && new_count > 0
	    let b:diffhl.add += range(new_line, new_line + new_count - 1)
	elseif old_count > 0 && new_count == 0
	    if new_line == 0
		let new_line = 1
	    endif
	    let b:diffhl.del += range(new_line, new_line + old_count - 1)
	" Line changed
	elseif old_count >= new_count
	    let b:diffhl.ch += range(new_line, new_line + new_count - 1)
	else
	    let b:diffhl.ch += range(new_line, new_line + old_count - 1)
	    let b:diffhl.add += range(new_line, new_line + new_count - 1)
	endif
    endfor
endfu

fu! s:ReturnGitRepPath() "{{{1
    " return the top level of the repository path. This is needed, so
    " git show will correctly return the file
    "exe 'lcd' fnamemodify(expand('%'), ':h')
    let git_path = system('git rev-parse --git-dir')
    if !v:shell_error
	" we need the directory right above the .git metatdata directory
	return escape(git_path[:-2].'/..', ' ')
    else
	return ''
    endif
    " OLD....
    let file  =  fnamemodify(expand("#"), ':p')
    let path  =  fnamemodify(file, ':h')
    let dir   =  finddir('.git',path.';')
    if empty(dir)
	throw 'changes: No git Repository found'
    else
	return fnamemodify(dir, ':h')
	let ldir  =  strlen(substitute(dir, '.', 'x', 'g'))-4
	if ldir
	    return file[ldir :]
	else
	    return ''
	endif
    endif
endfu

fu! s:ShowDifferentLines() "{{{1
    let b=copy(s:placed_signs[0])
    let b=map(b, 'matchstr(v:val, ''line=\zs\d\+'')')
    let b=map(b, '''\%(^\%''.v:val.''l\)''')
    if !empty(b)
	exe ":silent! lvimgrep /".join(b, '\|').'/gj %'
	lw
    else
	" This should not happen!
	call setloclist(winnr(),[],'a')
	lclose
    endif
endfun

fu! s:PlacedSigns() "{{{1
    if !exists("s:sign_prefix")
	return [[],[]]
    endif
    redir => a| exe "silent sign place buffer=".bufnr('')|redir end
    let b=split(a,"\n")[1:]
    if empty(b)
	return [[],[]]
    else
	" Filter from the second item. The first one contains the buffer name:
	" Signs for [NULL]: or  Signs for <buffername>:
	let b=b[1:]
    endif
    let c=filter(copy(b), 'v:val =~ "id=".s:sign_prefix')
    let d=filter(copy(b), 'v:val !~ "id=".s:sign_prefix')
    return [c,d]
endfu

fu! s:GuessVCSSystem() "{{{1
    " Check global config variable
    if exists("g:changes_vcs_system")
	let vcs=matchstr(g:changes_vcs_system, '\c\(git\)\|\(hg\)\|\(bzr\)\|\(svk\)\|\(cvs\)\|\(svn\)'.
		    \ '\|\(subversion\)\|\(mercurial\)\|\(rcs\)\|\(fossil\)\|\(darcs\)')
	if vcs
	    return vcs
	endif
    endif
    let file = fnamemodify(expand("%"), ':p')
    let path = escape(fnamemodify(file, ':h'), ' ')
    " First try git and hg, they seem to be the most popular ones these days
    if !empty(finddir('.git',path.';'))
	return 'git'
    elseif !empty(finddir('.hg',path.';'))
	return 'hg'
    elseif isdirectory(path . '/CVS')
	return 'cvs'
    elseif isdirectory(path . '/.svn')
	return 'svn'
    elseif !empty(finddir('.bzr',path.';'))
	return 'bzr'
    elseif !empty(findfile('_FOSSIL_', path.';'))
	return 'fossil'
    elseif !empty(finddir('_darcs', path.';'))
	return 'darcs'
    elseif !empty(finddir('RCS', path.';'))
	return 'rcs'
    " Is this correct for svk?
    elseif !empty(finddir('.svn',path.';'))
	return 'svk'
    else
	return ''
    endif
endfu

fu! s:CheckDeletedLines() "{{{1
    " If there are consecutive deleted lines,
    " we keep only the first of the deleted lines
    let i=0
    for item in b:diffhl['del']
	if item > line('$')
	    let b:diffhl['del'][i]=line('$')
	    return
	endif
	if i==0
	    let i+=1
	    let last_line = item
	    continue
	endif
	if last_line ==? (item-1)
	    call remove(b:diffhl['del'], i)
	    let last_line=item
	    continue
	endif
	let last_line=item
	let i+=1
    endfor
endfu

fu! s:MoveToPrevWindow() "{{{1
    let winnr = winnr()
    noa wincmd p
    if winnr() == winnr
	" Best effort, there doesn't exist a previous window
	" where wincmd p can jump to, so move to the next window
	" (e.g. latexsuite does this:
	" https://github.com/chrisbra/changesPlugin/issues/5
	noa wincmd w
    endif
endfu

fu! s:Is(os) "{{{1
    if (a:os == "win")
        return has("win32") || has("win16") || has("win64")
    elseif (a:os == "mac")
        return has("mac") || has("macunix")
    elseif (a:os == "unix")
        return has("unix") || has("macunix")
    endif
endfu

fu! s:RemoveConsecutiveLines(fwd, list) "{{{1
    " only keep the start/end of a bunch of successive lines
    let temp  = -1
    let lines = a:list
    for item in a:fwd ? lines : reverse(lines)
	if  ( a:fwd && temp == item - 1) ||
	\   (!a:fwd && temp == item + 1)
	    call remove(lines, index(lines, item))
	endif
	let temp = item
    endfor
    return lines
endfu

fu! s:GetDiff(arg, bang, ...) "{{{1
    " a:arg == 1 Create signs
    " a:arg == 2 Show changed lines in locationlist
    " a:arg == 3 Stay in diff mode
    
    " If error happened, don't try to get a diff list
    try
	if (exists("s:ignore") && get(s:ignore, bufnr('%'), 0) && empty(a:bang)) ||
	    \ !empty(&l:bt) ||
	    \ line2byte(line('$')) == -1
	    call add(s:msg, 'Buffer is ignored, use ! to force command')
	    " ignore error messages
	    if get(s:ignore, bufnr('%'), 0)
		call remove(s:ignore, bufnr('%'))
	    endif
	    return
	endif

	" Save some settings
	" fdm, wrap, and fdc will be reset by :diffoff!
	let _settings = [ &fdm, &lz, &fdc, &wrap, &diff ]
	let _wsv   = winsaveview()
	" Lazy redraw
	setl lz
	let isfolded = foldclosed('.')
	let scratchbuf = 0

	try
	    call s:PlaceSignDummy(1)
	    call changes#Init()

	    if !filereadable(bufname(''))
		call add(s:msg,"You've opened a new file so viewing changes ".
		    \ "is disabled until the file is saved ".
		    \ "(You have to reenable it if not using autocmd).")
		let s:verbose = 0
		return
	    endif

	    " Does not make sense to check an empty buffer
	    if empty(bufname(''))
		call add(s:msg,"The buffer does not contain a name. Check aborted!")
		let s:ignore[bufnr('%')] = 1
		let s:verbose = 0
		return
	    endif

	    let b:diffhl={'add': [], 'del': [], 'ch': []}
	    if a:arg == 3
		let s:temp = {'del': []}
		let curbuf = bufnr('%')
		let _ft = &ft
		let scratchbuf = s:MakeDiff(exists("a:1") ? a:1 : '')
		call s:CheckLines(1)
		exe "noa" bufwinnr(scratchbuf) "wincmd w"
		exe "setl ft=". _ft
		"call s:MoveToPrevWindow()
		call s:CheckLines(0)
		" Switch to other buffer and check for deleted lines
		"call s:MoveToPrevWindow()
		exe "noa" bufwinnr(curbuf) "wincmd w"
		let b:diffhl['del'] = s:temp['del']
	    else
		let scratchbuf = s:MakeDiff_new(exists("a:1") ? a:1 : '')
	    endif

	    " Check for empty dict of signs
	    if (empty(values(b:diffhl)[0]) && 
	    \empty(values(b:diffhl)[1]) && 
	    \empty(values(b:diffhl)[2]))
		call add(s:msg, 'No differences found!')
		let s:verbose=0
		let s:nodiff=1
	    else
		call s:PlaceSigns(b:diffhl)
	    endif
	    " :diffoff resets some options (see :h :diffoff
	    " so we need to restore them here
	    " We don't reset the fdm, in case we are staying in diff mode
	    if a:arg != 3 || s:nodiff
		if  _settings[2] == 1
		    " When foldcolumn is 1, folds won't be shown because of
		    " the signs, so increasing its value by 1 so that folds will
		    " also be shown
		    let _settings[2] += 1
		endif
		let b:changes_view_enabled=1
	    endif
	    if a:arg ==# 2
	    call s:ShowDifferentLines()
	    let s:verbose=0
	    endif
	catch /^Vim\%((\a\+)\)\=:E139/	" catch error E139
	    return
	catch /^changes/
	    let b:changes_view_enabled=0
	    let s:ignore[bufnr('%')] = 1
	    let s:verbose = 0
	finally
	    if scratchbuf && a:arg < 3
		exe "bw" scratchbuf
	    endif
	    if s:vcs && exists("b:changes_view_enabled") && b:changes_view_enabled
		call add(s:msg,"Check against " . fnamemodify(expand("%"),':t') . " from " . b:vcs_type)
	    endif
	    " remove dummy sign
	    call s:PlaceSignDummy(0)
	    " redraw (there seems to be some junk left)
	    redr!
	    call changes#Output(0)
	    if a:arg < 3
		let [ &fdm, &lz, &fdc, &wrap, &diff ] = _settings
	    else
		let [ &lz, &fdc, &wrap ] = _settings[1:3]
	    endif
	    if isfolded == -1 && foldclosed('.') != -1
		" resetting 'fdm' might fold the cursorline, reopen it
		norm! zv
	    endif
	endtry
    finally
	if exists("_wsv")
	    call winrestview(_wsv)
	endif
	" make sure on next call, s:sign-definition will be recreated by
	" DefinedSignsNotExists()
	unlet! s:sign_definition
	call changes#WarningMsg()
    endtry
endfu

fu! changes#WarningMsg() "{{{1
    if !&vbs
	" Set verbose to 1 to have messages displayed!
	return
    endif
    if !empty(s:msg)
	redraw!
	let msg=["Changes.vim: " . s:msg[0]] + s:msg[1:]
	echohl WarningMsg
	" s:echo_cmd might not yet exist
	if !exists("s:echo_cmd")
	    let s:echo_cmd = 'echo'
	endif
	for mess in msg
	    exe s:echo_cmd "mess"
	endfor

	echohl Normal
	let v:errmsg=msg[0]
	let s:msg = []
    endif
endfu

fu! changes#Output(force) "{{{1
    if s:verbose || a:force
	echohl Title
	echo "Differences will be highlighted like this:"
	echohl Normal
	echo "========================================="
	echohl DiffAdd
	echo "+ Added Lines"
	echohl DiffDelete
	echo "- Deleted Lines"
	echohl DiffChange
	echo "* Changed Lines"
	echohl Normal
    endif
endfu

fu! changes#Init() "{{{1
    " Message queue, that will be displayed.
    let s:msg      = []
    " Ignore buffer
    let s:ignore   = {}
    let s:hl_lines = get(g:, 'changes_hl_lines', 0)
    let s:autocmd  = get(g:, 'changes_autocmd', 0)
    let s:verbose  = get(g:, 'changes_verbose', &vbs)
    " Check against a file in a vcs system
    let s:vcs      = get(g:, 'changes_vcs_check', 0)
    if !exists("b:vcs_type")
	let b:vcs_type = (exists("g:changes_vcs_system")? g:changes_vcs_system : s:GuessVCSSystem())
    endif
    if !exists("s:vcs_cat")
	let s:vcs_cat  = {'git': 'show HEAD:', 
			 \'bzr': 'cat ', 
			 \'cvs': '-q update -p ',
			 \'darcs': '--show-contents ',
			 \'fossil': 'finfo -p ',
			 \'rcs': 'co -p ',
			 \'svn': 'cat ',
			 \'svk': 'cat ',
			 \'hg': 'cat '}

	" Define aliases...
	let s:vcs_cat.mercurial  = s:vcs_cat.hg
	let s:vcs_cat.subversion = s:vcs_cat.svn
    endif
"    if !exists("s:vcs_diff")
"	let s:vcs_diff  = {'git': 'diff -a -U0 --no-ext-diff -- ', 
"			 \'bzr': 'diff --using diff --diff-options=-U0 -- ', 
"			 \'cvs': '-q diff -U0 -- ',
"			 \'darcs': 'diff --no-pause-for-gui --diff-command="diff -U0 %1 %2" -- ',
"			 \'fossil': 'fossil diff --unified -- ',
"			 \'rcs': 'rcsdiff -U0 ',
"			 \'svn': 'diff -x -u --ignore-eol-style -- ',
"			 \'svk': 'diff -x -u --ignore-eol-style -- ',
"			 \'hg': 'diff -U0 --nodates -- '}
"	" Define aliases...
"	let s:vcs_diff.subversion = s:vcs_diff.svn
"	let s:vcs_diff.mercurial  = s:vcs_diff.hg
"    endif

    " Settings for Version Control
    if s:vcs
	if get(s:vcs_cat, b:vcs_type, 'NONE') == 'NONE'
	    call add(s:msg,"Don't know VCS " . b:vcs_type)
	    call add(s:msg,"VCS check will be disabled for now.")
	    let s:vcs=0
	    throw 'changes:NoVCS'
	endif
	if !executable(b:vcs_type)
	    call add(s:msg,'Guessing VCS: '. b:vcs_type)
	    call add(s:msg,"Executable " . b:vcs_type . " not found! Aborting.")
	    call add(s:msg,'You might want to set the g:changes_vcs_system variable to override!')
	    throw "changes:abort"
	endif
    endif
    if !exists("s:diff_out")
	let s:diff_out    = tempname()
	let s:diff_in_cur = tempname()
	let s:diff_in_old = tempname()
    endif
    let s:nodiff=0

    let s:signs={}
    let s:signs["add"] = "text=+ texthl=DiffAdd " . ( (s:hl_lines) ? " linehl=DiffAdd" : "")
    let s:signs["del"] = "text=- texthl=DiffDelete " . ( (s:hl_lines) ? " linehl=DiffDelete" : "")
    let s:signs["ch"] = "text=* texthl=DiffChange " . ( (s:hl_lines) ? " linehl=DiffChange" : "")
    let s:signs["dummy"] = "text=_ texthl=SignColumn "

    " Only check the first time this file is loaded
    " It should not be neccessary to check every time
    if !exists("s:precheck")
	try
	    call s:Check()
	catch
	    " Rethrow exception
	    throw v:exception
	endtry
	let s:precheck=1
    endif

    let s:placed_signs = s:PlacedSigns()
    " Delete previously placed signs
    call s:UnPlaceSigns(0)
    if exists("s:sign_definition")
	let def = s:DefinedSignsNotExists()
	if (     match(def, s:signs.add) == -1
	    \ || match (def, s:signs.del) == -1
	    \ || match (def, s:signs.ch)  == -1)
	    " Sign definition changed, redefine them
	    call s:DefineSigns()
	endif
    else
	call s:DefineSigns()
    endif
    call s:AuCmd(s:autocmd)
endfu

fu! changes#EnableChanges(arg, bang, ...) "{{{1
    if exists("s:ignore") && get(s:ignore, bufnr('%'), 0)
	call remove(s:ignore, bufnr('%'))
    endif
    if exists("a:1")
	call s:GetDiff(a:arg, a:bang, a:1)
    else
	call s:GetDiff(a:arg, a:bang)
    endif
endfu

fu! changes#CleanUp() "{{{1
    " only delete signs, that have been set by this plugin
    call s:UnPlaceSigns(1)
    let s:ignore[bufnr('%')] = 1
    if !exists("s:signs") || !exists("s:autocmd")
	return
    endif
    for key in keys(s:signs)
	exe "sil! sign undefine " key
    endfor
    if s:autocmd
	call s:AuCmd(0)
    endif
endfu

fu! changes#TCV() "{{{1
    if  exists("b:changes_view_enabled") && b:changes_view_enabled
	call s:UnPlaceSigns(1)
	if exists("b:ofdc")
	    let &fdc=b:ofdc
	endif
        let b:changes_view_enabled = 0
        echo "Hiding changes since last save"
    else
	call s:GetDiff(1, '')
        let b:changes_view_enabled = 1
        echo "Showing changes since last save"
    endif
endfunction

fu! changes#MoveToNextChange(fwd, cnt) "{{{1
    " Make sure, the hunks are up to date
    let _fen = &fen
    set nofen
    call s:UpdateView()
    let &fen = _fen

    let cur = line('.')
    let dict = get(b:, "diffhl", {})
    let lines = get(dict, "add", []) +
	    \   get(dict, "del", []) +
	    \   get(dict, "ch",  [])
    let cnt = a:cnt-1

    " only keep the start/end of a bunch of successive lines
    let lines = s:RemoveConsecutiveLines(1, copy(lines)) +
	      \ s:RemoveConsecutiveLines(0, copy(lines))

    if !exists("b:diffhl") || empty(lines)
	echomsg "There are no ". (a:fwd ? "next" : "previous"). " differences!"
	return "\<esc>"
    elseif (a:fwd && max(lines) <= cur) ||
	\ (!a:fwd && min(lines) >= cur)
	echomsg "There are no more ". (a:fwd ? "next" : "previous"). " differences!"
	return "\<esc>"
    endif
    if a:fwd
	call filter(lines, 'v:val > cur')
	if empty(lines)
	    return "\<esc>"
	else
	    call sort(lines)
	endif
    else
	call filter(lines, 'v:val < cur')
	if empty(lines)
	    return "\<esc>"
	else
	    call reverse(sort(lines))
	endif
    endif
    if cnt > len(lines)
	let cnt=length(lines)
    endif

    if cnt > 0
	" Cancel the user given count
	" otherwise the count would be multiplied with
	" the given line number
	let prefix="\<esc>"
    else
	let prefix=""
    endif
    return prefix.lines[cnt]. "G"
endfu

fu! changes#CurrentHunk() "{{{1
    if changes#MoveToNextChange(0) == "\<Esc>"
	" outside of a hunk
	return "\<Esc>"
    else
	return "[ho]h"
    endif
endfu
" Old functions "{{{1
fu! s:DiffOff() "{{{2
    if !&diff
	return
    endif
    " Turn off Diff Mode and close buffer
    call s:MoveToPrevWindow()
    diffoff!
    q
endfu


" Modeline "{{{1
" vi:fdm=marker fdl=0
doc/ChangesPlugin.txt	[[[1
391
*ChangesPlugin.txt*  Print indication of changed lines for a buffer

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.14 Wed, 14 Aug 2013 22:10:39 +0200
Copyright: (c) 2010-2013 by Christian Brabandt        *ChangesPlugin-copyright*
           The VIM LICENSE applies to ChangesPlugin.txt (see |copyright|)
           except use unicode instead of "Vim".  NO WARRANTY, EXPRESS OR
           IMPLIED.  USE AT-YOUR-OWN-RISK.

==============================================================================
1. Contents                                                   *ChangesPlugin*

  1.  Contents......................................: |ChangesPlugin|
  2.  Manual........................................: |ChangesPlugin-manual|
  3.  Configuration.................................: |ChangesPlugin-Config|
   3.1 Highlighting whole lines.....................: |ChangesPlugin-hlLine|
   3.2 Auto-refresh changes.........................: |ChangesPlugin-aucmd|
   3.3 Show the meaning of the indicator bars.......: |ChangesPlugin-bars|
   3.4 Specify different colors.....................: |ChangesPlugin-colors|
   3.5 Check against a file in a VCS................: |ChangesPlugin-VCS|
   3.6 Get error messages...........................: |ChangesPlugin-errors|
   3.7 Display unified diff in preview window.......: |ChangesPlugin-preview|
   3.8 Don't overwrite other signs..................: |ChangesPlugin-others|
  4.  ChangesPlugin Feedback........................: |ChangesPlugin-Feedback|
  5.  ChangesPlugin History.........................: |ChangesPlugin-history|

==============================================================================

                                                       *ChangesPlugin-manual*
2. Functionality

This plugin was written to help visualize which lines have been changes since
editing started for a file. The plugin was inspired by so called changed-bars,
available at other editors, such as Embarcadero C++ Builder (there it is
called Change Bars, see:
http://edn.embarcadero.com/article/33453#6PersonalDeveloperProductivity)
or Visual Studio where it is called indicator margin (see
http://blog.eveningcreek.com/?p=151).

ChangesPlugin.vim uses the |diff|-feature of vim and compares the actual
buffer with it's saved state. In order to highlight the indicator signs at the
first column, its using |signs|. For newly added lines, the first column will
be displayed with a leading '+' and highlighted using the DiffAdd highlighting
(see |hl-DiffAdd|), deleted lines will be indicated by a '-' with a
DiffDelete highlighting (see |hl-DiffDelete|) and modified lines will be
displayed using '*' and a DiffChange highlighting (see |hl-DiffChange|).

Note, that a '-' will be shown on the next line after the deleted lines. A
range of consecutive deleted lines will be displayed by only one '-'

This means, that in order to use this plugin you need a vim, that was built
with |+signs|-support and |+diff|-support and you also need an executable diff
command. If neither of these conditions are met, changePlugin.vim will issue a
warning and abort.

                                                         *:EC* *:EnableChanges*
By default the plugin is not enabled. To enable it enter >
    :EnableChanges
When you run this command, ChangesPlugin.vim diffs the current file agains
its saved file on disk and displays the changes in the first column.

If you like to display the Changes against a different file, simply supply its
filename as optional argument to that command, e.g. >
    :EnableChanges ~/project/foobar.c
would display the Signs as if your current file has been diffed against the
file ~/project/foobar.c

Alternatively, you can enter the shortcut >
     :EC
which basically calls :EnableChanges and supports the same arguments.

If errors happen, the current buffer will be silently ignored when :EC
is called later. Use the ! attribute, to force reevaluating the command (and
see error messages).

                                                        *:DC* *:DisableChanges*
If you want to disable the plugin, enter >
    :DisableChanges
or alternatively, you can enter the shortcut >
     :DC
and the Display of Changes will be disabled.

                                                     *:TCV* *:ToggleChangeView*
You can toggle, between turning on and off the indicator bars, using >
     :ToggleChangeView
or alternatively: >
     :TCV
to toggle the display of indicator bars.

                                                     *:CC* *:ChangesCaption*
You are probably wondering, what those strange looking signs mean. You can use
either >
    :CC
or >
    :ChangesCaptions
to let the Plugin display a small caption, so you know what each sign means
and how they are colored.

                                                 *:CL* *:ChangesLineOverview*
If you are editing a huge file with several hundreds of lines, it may be hard
to find the lines that have been changed. >
    :CL
or >
    :ChangesLineOverview
provide an easy view to only see all modified lines. This will open the
|location-list| buffer where you can easily see the affected lines. Pushing
enter on any line, allows you to easily jump to that line in the buffer.

                                                 *:CD* *:ChangesDiffMode*
You might want to keep the diff-window open, so you can use it for modifying
your buffer using e.g. |:diffput| or |:diffget|
Therefore ChangesPlugin defines the two commands >
    :CD
and >
    :ChangesDiffMode
If you issue any of these commands, a vertical split buffer will open,
that contains the changes from either your VCS or from the unmodified buffer
as it is saved on disk. See |copy-diffs| for how to merge changes between
those two buffers.
                                                *ChangesPlugin-Maps* *[h* *]h*
ChangesPlugin also sets up some mappings to move from one changed line to
another. By default, those mappings are defined:

`[h`        move backwards to the next changed line,
`]h`        moves forward to the next changed line.
                                                                    *v_ah*
`ah`        selects the current hunk (only in Visual and Operator pending mode)

==============================================================================
                                                        *ChangesPlugin-Config*
3. Configuring ChangesPlugin.vim

There are several different configuration options available.

                                                        *ChangesPlugin-hlLine*
3.1 Highlighte the whole line
-----------------------------

By default, ChangesPlugin.vim will only indicate a change in the first column.
Setting g:changes_hl_lines to 1 will highlight the whole line. By default this
variable is unset (which is the same as setting it to 0).
If you'd like to have this, set this variable in your |.vimrc| >

    :let g:changes_hl_lines=1
<
                                                        *ChangesPlugin-aucmd*
3.2 Auto-refresh the changes
----------------------------

By default ChangesPlugin.vim will not automatically update the view. You can
however configure it to do so. This will use an |CursorHold| and |InsertLeave|
utocommand to update the indicator signs after |'updatetime'| seconds in
Normal mode when no key is pressed. To enable this feature, put this in your
|.vimrc| >
    let g:changes_autocmd=1

This autocommand checks, whether there have been changes to the file, or else
it won't update the view.

                                                        *ChangesPlugin-bars*
3.3 Show what the indicator signs mean
--------------------------------------

By default, whenever you run |:EnableChanges|, changesVim will print a short
status message, what each sign means. If you don't want this, put this in your
|.vimrc| >

    :let g:changes_verbose=0

and achangesPlugin won't display this message again. You can always issue the
|CL| command to find out, what each sign means.
                                                        *ChangesPlugin-colors*

3.4 Specify different colors
----------------------------

changesVim uses the highlighting used for |diff| mode to indicate the change
in a buffer. This is consistent, since when you're already used to |vimdiff|
you'll probably also know the highlighting. If for any reason you do not like
the colors, you have to define your own highlighting items.
If for example you want the DiffAdd highlighting to be displayed like White on
a Blue background, you can define it as follows in your |.vimrc| >

    :hi DiffAdd term=bold ctermbg=4 guibg=DarkBlue

In the same way, you can change DiffDelete for indicating deleted lines and
DiffChange for indicating modified lines. You can also specify your favorite
highlighting colors using your own build |colorscheme|.

                                                          *ChangesPlugin-VCS*
3.5 Check differences against a checked-in file from a VCS
----------------------------------------------------------

Warning: This feature is rather experimental. So use it with care.

You can configure ChangesPlugin to check the differrences of the current
buffer not only against the file stored on disk, but rather query a Version
Control System (VCS) for its latest version and indicate changes based on
this version.

Currently, ChangesPlugin supports these VCS Systems:
    - git
    - hg
    - svn
    - cvs
    - bzr
    - darcs
    - fossil
    - svk
    - RCS

To enable this feature, you need to set the variable g:changes_vcs_check to
1. ChangesPlugin will then try to auto-detect, which of the above supported
VCS-Systems is in use. That means, if it can't detect neither of git, cvs,
svn, bzr or hg it will assume you are using svk. This may fail obviously, so
you can always force ChangesPlugin to use any of the above by setting the
g:changes_vcs_system Variable.

To enable this feature, you need to set the g:changes_vcs_check variable to 1.
The following example enables this feature and ensures, EnablePlugin is using
git as VCS, so these lines have been entered in the |.vimrc| >

    :let g:changes_vcs_check=1
    :let g:changes_vcs_system='git'

Note, that depending on the VCS System you use, this might slow down
ChangesPlugin significantly. Especially CVS seems to be very slow.

Note also, that setting g:changes_vcs_system is setting a global variable (see
|g:-var|) and therefore would set the VCS for every buffer opened in vim (thus
you could use changesPlugin only with one single VCS). However, guessing the
VCS System should work fairely well and in case it doesn't, please report a
bug to the maintainer of the plugin. Setting g:changes_vcs_check will however
disable the check against the on-disk version of a buffer.

                                                          *ChangesPlugin-errors*
3.6 Get error messages
----------------------

By default the plugin will not display error messages. If you want to see
them, set the 'verbose' option to 1.

                                                          *ChangesPlugin-preview*
3.7 Display the unified diff in the preview window
--------------------------------------------------

If you'd like to see the diff of the changes, you can set the variable
g:changes_diff_preview. e.g. in your |.vimrc| set >

    :let g:changes_diff_preview = 1
<
This will display and update the preview window, whenever the indicator signs
are displayed.

                                                          *ChangesPlugin-others*
3.8 Don't overwrite other signs
-------------------------------

By default the plugin places its signs on lines, on which already has been
placed a sign. To prevent this, set the variable g:changes_respect_other_signs
to 1 (e.g. in your |.vimrc| place >

    :let g:changes_respect_other_signs = 1
<
This will prevent placing signs on lines, on which other plugins have already
placed their signs, which would then be overwritten).

==============================================================================
4. ChangesPlugin Feedback                           *ChangesPlugin-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3052

You can also follow the development of the plugin at github:
http://github.com/chrisbra/changesPlugin

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
5. ChangesPlugin History                                *ChangesPlugin-history*

    BF: Bugfix
    NF: New Feature

    0.14: Aug 14, 2013:                                                 {{{1
        BF: Exception not caught (reported by Marco, thanks!)
        BF: Prevent flickering by resetting SignColumn on
        updates (reported by Marco, thanks!)
        BF: parse diff output instead of relying on vimdiff
        and parsing the syntax items (prevents flickering
        since no window needs to be split)
        BF: avoid error messages, when buffer is ignored
        (https://github.com/chrisbra/changesPlugin/issues/6
        reported by mpfusion, thanks!)
        BF: avoid error messages, using |DC|
        (https://github.com/chrisbra/changesPlugin/issues/7
        reported by mpfusion, thanks!)
        BF: don't mess with the |alternate-file|
        (https://github.com/chrisbra/changesPlugin/issues/8
        reported by mpfusion, thanks!)
        NF: |ChangesPlugin-preview|
        NF: |ChangesPlugin-Maps|
            [h/]h move to previous/next changed line
    0.13: Feb 16, 2013:                                                 {{{1
        BF: Plugin used :EnableDisplayChanges, but
        documentation talked about EnableChanges
        (same for DisableChanges)
        BF: Don't load the autoload script when sourcing
        the plugin (reported by Sergey Kholev, thanks!)
    0.12: Jan, 31, 2012:                                                {{{1
        NF: Fix issue #3 from github (check changes against
            any file, suggested by Alessio Bolognino, Thanks!)
        BF: Fix E117 error (patch by Mate Gabri, Thanks!)
        BF: Check, that the current file is readable, before
            diffing (patch by Mate Gabri, Thanks!)
        BF: Sometimes, the previous Window is not accessible
            anymore
            (http://github.com/chrisbra/changesPlugin/issues/5
            by Mate Gabri, Thanks!)
    0.11: May 04, 2010:                                                 {{{1
        BF: Document, that |InsertLeave| autocommand is used
            as autocommand
        BF: generate the help file with 'et' set, so that the
            README at github looks prettier
        BF: When staying in diff mode, don't reset 'fdm'
            and apply syntax coloring to scratch buffer
        BF: the check for the diff executable does not work
            as expected (Reported by Sergey Khorev),
            additionally outputting the Warnings did not work
            in that case
    0.10: Apr 28, 2010:                                                 {{{1
        NF: Fixed Issue 1 from github
            (http://github.com/chrisbra/changesPlugin/issues/1/find)
    0.9: Apr 24, 2010:                                                  {{{1
        NF: You can now use different VCS Systems for each
            buffer you are using.
        NF: Stay in diff mode
        BF: Fix the display of deleted signs
        BF: Undefining old signs, so that changing
            g:changes_hl_lines works
        BF: Some more error handling.
        NF: Show an overview for changed lines in location-list
            (|:CL|)
        NF: Show what each sign means using |:CC|
    0.8: Apr 22, 2010:                                                  {{{1
        NF: Renamed the helpfile, to make it more obvious,
        that it refers to a plugin
        NF: Outputting name of checked file, if checking
            against VCS
        BF: Don't check for empty files.
        BF: Reworked the Message function
        BF: Don't try to place signs, if there are no
            differences
            (unreleased, VCS successfully tested with
                git, hg, svn, cvs, bzr)
    0.7: Apr 19, 2010:                                                  {{{1
        NF: Check against a file in a VCS
            (unreleased, first working version,
            needs to be checked for each VCS)
    0.6: Apr 12, 2010:                                                  {{{1
        BF: fixed a missing highlight for DiffText
    0.5: Apr 12, 2010:                                                  {{{1
        BF: error when trying to access b:diffhl in the
            scratch buffer. This should be fixed now (thanks
            Jeet Sukumaran!)
        BF: Use the correct highlighting groups (thanks Jeet
            Sukumaran!)
    0.4: Apr 12, 2010:                                                  {{{1
        NF: |ToggleChangesView|
        NF: The autocommand checks, if the buffer has been
            modified, since the last time.
        BF: Do not mess with signs, that have not been placed
            by ChangesPlugin.vim
        BF: CleanUp was seriously messed up (sorry, I must
            have been asleep, when writing that)
        BF: Take care of 'foldcolumn' setting, which would be
            overwritten by the signs-column
    0.3: Apr 11, 2010:                                                  {{{1
        BF: redraw, so that the diff window will not be
            displayed
        NF: enabled GLVS (see |GLVS|)
    0.2: Apr 11, 2010:                                                  {{{1
        Added Documentation
        created an autoload version
    0.1: Apr 10, 2010:                                                  {{{1
        First working version
Modeline: {{{1
==============================================================================
vim:tw=78:ts=8:ft=help:et:fdm=marker:fdl=0
