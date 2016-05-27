" vim-plug: Vim plugin manager
" ============================
"
" Download plug.vim and put it in ~/.vim/autoload
"
"   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"
" Edit your .vimrc
"
"   call plug#begin('~/.vim/plugged')
"
"   " Make sure you use single quotes
"
"   " Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
"   Plug 'junegunn/vim-easy-align'
"
"   " Any valid git URL is allowed
"   Plug 'https://github.com/junegunn/vim-github-dashboard.git'
"
"   " Group dependencies, vim-snippets depends on ultisnips
"   Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
"
"   " On-demand loading
"   Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
"   Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
"
"   " Using a non-master branch
"   Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }
"
"   " Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
"   Plug 'fatih/vim-go', { 'tag': '*' }
"
"   " Plugin options
"   Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }
"
"   " Plugin outside ~/.vim/plugged with post-update hook
"   Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
"
"   " Unmanaged plugin (manually installed and updated)
"   Plug '~/my-prototype-plugin'
"
"   " Add plugins to &runtimepath
"   call plug#end()
"
" Then reload .vimrc and :PlugInstall to install plugins.
"
" Plug options:
"
"| Option                  | Description                                      |
"| ----------------------- | ------------------------------------------------ |
"| `branch`/`tag`/`commit` | Branch/tag/commit of the repository to use       |
"| `rtp`                   | Subdirectory that contains Vim plugin            |
"| `dir`                   | Custom directory for the plugin                  |
"| `as`                    | Use different name for the plugin                |
"| `do`                    | Post-update hook (string or funcref)             |
"| `on`                    | On-demand loading: Commands or `<Plug>`-mappings |
"| `for`                   | On-demand loading: File types                    |
"| `frozen`                | Do not update unless explicitly specified        |
"
" More information: https://github.com/junegunn/vim-plug
"
"
" Copyright (c) 2016 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:loaded_plug')
  finish
endif
let g:loaded_plug = 1

let s:cpo_save = &cpo
set cpo&vim

let s:plug_src = 'https://github.com/junegunn/vim-plug.git'
let s:plug_tab = get(s:, 'plug_tab', -1)
let s:plug_buf = get(s:, 'plug_buf', -1)
let s:mac_gui = has('gui_macvim') && has('gui_running')
let s:is_win = has('win32') || has('win64')
let s:nvim = has('nvim') && exists('*jobwait') && !s:is_win
let s:me = resolve(expand('<sfile>:p'))
let s:base_spec = { 'branch': 'master', 'frozen': 0 }
let s:TYPE = {
\   'string':  type(''),
\   'list':    type([]),
\   'dict':    type({}),
\   'funcref': type(function('call'))
\ }
let s:loaded = get(s:, 'loaded', {})
let s:triggers = get(s:, 'triggers', {})

function! plug#begin(...)
  if a:0 > 0
    let s:plug_home_org = a:1
    let home = s:path(fnamemodify(expand(a:1), ':p'))
  elseif exists('g:plug_home')
    let home = s:path(g:plug_home)
  elseif !empty(&rtp)
    let home = s:path(split(&rtp, ',')[0]) . '/plugged'
  else
    return s:err('Unable to determine plug home. Try calling plug#begin() with a path argument.')
  endif

  let g:plug_home = home
  let g:plugs = {}
  let g:plugs_order = []
  let s:triggers = {}

  call s:define_commands()
  return 1
endfunction

function! s:define_commands()
  command! -nargs=+ -bar Plug call plug#(<args>)
  if !executable('git')
    return s:err('`git` executable not found. Most commands will not be available. To suppress this message, prepend `silent!` to `call plug#begin(...)`.')
  endif
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugInstall call s:install(<bang>0, [<f-args>])
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugUpdate  call s:update(<bang>0, [<f-args>])
  command! -nargs=0 -bar -bang PlugClean call s:clean(<bang>0)
  command! -nargs=0 -bar PlugUpgrade if s:upgrade() | execute 'source' s:esc(s:me) | endif
  command! -nargs=0 -bar PlugStatus  call s:status()
  command! -nargs=0 -bar PlugDiff    call s:diff()
  command! -nargs=? -bar -bang -complete=file PlugSnapshot call s:snapshot(<bang>0, <f-args>)
endfunction

function! s:to_a(v)
  return type(a:v) == s:TYPE.list ? a:v : [a:v]
endfunction

function! s:to_s(v)
  return type(a:v) == s:TYPE.string ? a:v : join(a:v, "\n") . "\n"
endfunction

function! s:glob(from, pattern)
  return s:lines(globpath(a:from, a:pattern))
endfunction

function! s:source(from, ...)
  let found = 0
  for pattern in a:000
    for vim in s:glob(a:from, pattern)
      execute 'source' s:esc(vim)
      let found = 1
    endfor
  endfor
  return found
endfunction

function! s:assoc(dict, key, val)
  let a:dict[a:key] = add(get(a:dict, a:key, []), a:val)
endfunction

function! s:ask(message)
  call inputsave()
  echohl WarningMsg
  let proceed = input(a:message.' (y/N) ') =~? '^y'
  echohl None
  call inputrestore()
  echo "\r"
  return proceed
endfunction

function! plug#end()
  if !exists('g:plugs')
    return s:err('Call plug#begin() first')
  endif

  if exists('#PlugLOD')
    augroup PlugLOD
      autocmd!
    augroup END
    augroup! PlugLOD
  endif
  let lod = { 'ft': {}, 'map': {}, 'cmd': {} }

  filetype off
  for name in g:plugs_order
    let plug = g:plugs[name]
    if get(s:loaded, name, 0) || !has_key(plug, 'on') && !has_key(plug, 'for')
      let s:loaded[name] = 1
      continue
    endif

    if has_key(plug, 'on')
      let s:triggers[name] = { 'map': [], 'cmd': [] }
      for cmd in s:to_a(plug.on)
        if cmd =~? '^<Plug>.\+'
          if empty(mapcheck(cmd)) && empty(mapcheck(cmd, 'i'))
            call s:assoc(lod.map, cmd, name)
          endif
          call add(s:triggers[name].map, cmd)
        elseif cmd =~# '^[A-Z]'
          if exists(':'.cmd) != 2
            call s:assoc(lod.cmd, cmd, name)
          endif
          call add(s:triggers[name].cmd, cmd)
        else
          call s:err('Invalid `on` option: '.cmd.
          \ '. Should start with an uppercase letter or `<Plug>`.')
        endif
      endfor
    endif

    if has_key(plug, 'for')
      let types = s:to_a(plug.for)
      if !empty(types)
        augroup filetypedetect
        call s:source(s:rtp(plug), 'ftdetect/**/*.vim', 'after/ftdetect/**/*.vim')
        augroup END
      endif
      for type in types
        call s:assoc(lod.ft, type, name)
      endfor
    endif
  endfor

  for [cmd, names] in items(lod.cmd)
    execute printf(
    \ 'command! -nargs=* -range -bang %s call s:lod_cmd(%s, "<bang>", <line1>, <line2>, <q-args>, %s)',
    \ cmd, string(cmd), string(names))
  endfor

  for [map, names] in items(lod.map)
    for [mode, map_prefix, key_prefix] in
          \ [['i', '<C-O>', ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
      execute printf(
      \ '%snoremap <silent> %s %s:<C-U>call <SID>lod_map(%s, %s, "%s")<CR>',
      \ mode, map, map_prefix, string(map), string(names), key_prefix)
    endfor
  endfor

  for [ft, names] in items(lod.ft)
    augroup PlugLOD
      execute printf('autocmd FileType %s call <SID>lod_ft(%s, %s)',
            \ ft, string(ft), string(names))
    augroup END
  endfor

  call s:reorg_rtp()
  filetype plugin indent on
  if has('vim_starting')
    if has('syntax') && !exists('g:syntax_on')
      syntax enable
    end
  else
    call s:reload()
  endif
endfunction

function! s:loaded_names()
  return filter(copy(g:plugs_order), 'get(s:loaded, v:val, 0)')
endfunction

function! s:reload()
  for name in s:loaded_names()
    call s:source(s:rtp(g:plugs[name]), 'plugin/**/*.vim', 'after/plugin/**/*.vim')
  endfor
endfunction

function! s:trim(str)
  return substitute(a:str, '[\/]\+$', '', '')
endfunction

function! s:version_requirement(val, min)
  for idx in range(0, len(a:min) - 1)
    let v = get(a:val, idx, 0)
    if     v < a:min[idx] | return 0
    elseif v > a:min[idx] | return 1
    endif
  endfor
  return 1
endfunction

function! s:git_version_requirement(...)
  if !exists('s:git_version')
    let s:git_version = map(split(split(s:system('git --version'))[-1], '\.'), 'str2nr(v:val)')
  endif
  return s:version_requirement(s:git_version, a:000)
endfunction

function! s:progress_opt(base)
  return a:base && !s:is_win &&
        \ s:git_version_requirement(1, 7, 1) ? '--progress' : ''
endfunction

if s:is_win
  function! s:rtp(spec)
    return s:path(a:spec.dir . get(a:spec, 'rtp', ''))
  endfunction

  function! s:path(path)
    return s:trim(substitute(a:path, '/', '\', 'g'))
  endfunction

  function! s:dirpath(path)
    return s:path(a:path) . '\'
  endfunction

  function! s:is_local_plug(repo)
    return a:repo =~? '^[a-z]:\|^[%~]'
  endfunction
else
  function! s:rtp(spec)
    return s:dirpath(a:spec.dir . get(a:spec, 'rtp', ''))
  endfunction

  function! s:path(path)
    return s:trim(a:path)
  endfunction

  function! s:dirpath(path)
    return substitute(a:path, '[/\\]*$', '/', '')
  endfunction

  function! s:is_local_plug(repo)
    return a:repo[0] =~ '[/$~]'
  endfunction
endif

function! s:err(msg)
  echohl ErrorMsg
  echom '[vim-plug] '.a:msg
  echohl None
endfunction

function! s:warn(cmd, msg)
  echohl WarningMsg
  execute a:cmd 'a:msg'
  echohl None
endfunction

function! s:esc(path)
  return escape(a:path, ' ')
endfunction

function! s:escrtp(path)
  return escape(a:path, ' ,')
endfunction

function! s:remove_rtp()
  for name in s:loaded_names()
    let rtp = s:rtp(g:plugs[name])
    execute 'set rtp-='.s:escrtp(rtp)
    let after = globpath(rtp, 'after')
    if isdirectory(after)
      execute 'set rtp-='.s:escrtp(after)
    endif
  endfor
endfunction

function! s:reorg_rtp()
  if !empty(s:first_rtp)
    execute 'set rtp-='.s:first_rtp
    execute 'set rtp-='.s:last_rtp
  endif

  " &rtp is modified from outside
  if exists('s:prtp') && s:prtp !=# &rtp
    call s:remove_rtp()
    unlet! s:middle
  endif

  let s:middle = get(s:, 'middle', &rtp)
  let rtps     = map(s:loaded_names(), 's:rtp(g:plugs[v:val])')
  let afters   = filter(map(copy(rtps), 'globpath(v:val, "after")'), 'isdirectory(v:val)')
  let rtp      = join(map(rtps, 'escape(v:val, ",")'), ',')
                 \ . ','.s:middle.','
                 \ . join(map(afters, 'escape(v:val, ",")'), ',')
  let &rtp     = substitute(substitute(rtp, ',,*', ',', 'g'), '^,\|,$', '', 'g')
  let s:prtp   = &rtp

  if !empty(s:first_rtp)
    execute 'set rtp^='.s:first_rtp
    execute 'set rtp+='.s:last_rtp
  endif
endfunction

function! s:doautocmd(...)
  if exists('#'.join(a:000, '#'))
    execute 'doautocmd' ((v:version > 703 || has('patch442')) ? '<nomodeline>' : '') join(a:000)
  endif
endfunction

function! s:dobufread(names)
  for name in a:names
    let path = s:rtp(g:plugs[name]).'/**'
    for dir in ['ftdetect', 'ftplugin']
      if len(finddir(dir, path))
        return s:doautocmd('BufRead')
      endif
    endfor
  endfor
endfunction

function! plug#load(...)
  if a:0 == 0
    return s:err('Argument missing: plugin name(s) required')
  endif
  if !exists('g:plugs')
    return s:err('plug#begin was not called')
  endif
  let unknowns = filter(copy(a:000), '!has_key(g:plugs, v:val)')
  if !empty(unknowns)
    let s = len(unknowns) > 1 ? 's' : ''
    return s:err(printf('Unknown plugin%s: %s', s, join(unknowns, ', ')))
  end
  for name in a:000
    call s:lod([name], ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  endfor
  call s:dobufread(a:000)
  return 1
endfunction

function! s:remove_triggers(name)
  if !has_key(s:triggers, a:name)
    return
  endif
  for cmd in s:triggers[a:name].cmd
    execute 'silent! delc' cmd
  endfor
  for map in s:triggers[a:name].map
    execute 'silent! unmap' map
    execute 'silent! iunmap' map
  endfor
  call remove(s:triggers, a:name)
endfunction

function! s:lod(names, types, ...)
  for name in a:names
    call s:remove_triggers(name)
    let s:loaded[name] = 1
  endfor
  call s:reorg_rtp()

  for name in a:names
    let rtp = s:rtp(g:plugs[name])
    for dir in a:types
      call s:source(rtp, dir.'/**/*.vim')
    endfor
    if a:0
      if !s:source(rtp, a:1) && !empty(s:glob(rtp, a:2))
        execute 'runtime' a:1
      endif
      call s:source(rtp, a:2)
    endif
    call s:doautocmd('User', name)
  endfor
endfunction

function! s:lod_ft(pat, names)
  let syn = 'syntax/'.a:pat.'.vim'
  call s:lod(a:names, ['plugin', 'after/plugin'], syn, 'after/'.syn)
  execute 'autocmd! PlugLOD FileType' a:pat
  call s:doautocmd('filetypeplugin', 'FileType')
  call s:doautocmd('filetypeindent', 'FileType')
endfunction

function! s:lod_cmd(cmd, bang, l1, l2, args, names)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  call s:dobufread(a:names)
  execute printf('%s%s%s %s', (a:l1 == a:l2 ? '' : (a:l1.','.a:l2)), a:cmd, a:bang, a:args)
endfunction

function! s:lod_map(map, names, prefix)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  call s:dobufread(a:names)
  let extra = ''
  while 1
    let c = getchar(0)
    if c == 0
      break
    endif
    let extra .= nr2char(c)
  endwhile
  call feedkeys(a:prefix . substitute(a:map, '^<Plug>', "\<Plug>", '') . extra)
endfunction

function! plug#(repo, ...)
  if a:0 > 1
    return s:err('Invalid number of arguments (1..2)')
  endif

  try
    let repo = s:trim(a:repo)
    let opts = a:0 == 1 ? s:parse_options(a:1) : s:base_spec
    let name = get(opts, 'as', fnamemodify(repo, ':t:s?\.git$??'))
    let spec = extend(s:infer_properties(name, repo), opts)
    if !has_key(g:plugs, name)
      call add(g:plugs_order, name)
    endif
    let g:plugs[name] = spec
    let s:loaded[name] = get(s:loaded, name, 0)
  catch
    return s:err(v:exception)
  endtry
endfunction

function! s:parse_options(arg)
  let opts = copy(s:base_spec)
  let type = type(a:arg)
  if type == s:TYPE.string
    let opts.tag = a:arg
  elseif type == s:TYPE.dict
    call extend(opts, a:arg)
    if has_key(opts, 'dir')
      let opts.dir = s:dirpath(expand(opts.dir))
    endif
  else
    throw 'Invalid argument type (expected: string or dictionary)'
  endif
  return opts
endfunction

function! s:infer_properties(name, repo)
  let repo = a:repo
  if s:is_local_plug(repo)
    return { 'dir': s:dirpath(expand(repo)) }
  else
    if repo =~ ':'
      let uri = repo
    else
      if repo !~ '/'
        let repo = 'vim-scripts/'. repo
      endif
      let fmt = get(g:, 'plug_url_format', 'https://git::@github.com/%s.git')
      let uri = printf(fmt, repo)
    endif
    let dir = s:dirpath( fnamemodify(join([g:plug_home, a:name], '/'), ':p') )
    return { 'dir': dir, 'uri': uri }
  endif
endfunction

function! s:install(force, names)
  call s:update_impl(0, a:force, a:names)
endfunction

function! s:update(force, names)
  call s:update_impl(1, a:force, a:names)
endfunction

function! plug#helptags()
  if !exists('g:plugs')
    return s:err('plug#begin was not called')
  endif
  for spec in values(g:plugs)
    let docd = join([spec.dir, 'doc'], '/')
    if isdirectory(docd)
      silent! execute 'helptags' s:esc(docd)
    endif
  endfor
  return 1
endfunction

function! s:syntax()
  syntax clear
  syntax region plug1 start=/\%1l/ end=/\%2l/ contains=plugNumber
  syntax region plug2 start=/\%2l/ end=/\%3l/ contains=plugBracket,plugX
  syn match plugNumber /[0-9]\+[0-9.]*/ contained
  syn match plugBracket /[[\]]/ contained
  syn match plugX /x/ contained
  syn match plugDash /^-/
  syn match plugPlus /^+/
  syn match plugStar /^*/
  syn match plugMessage /\(^- \)\@<=.*/
  syn match plugName /\(^- \)\@<=[^ ]*:/
  syn match plugSha /\%(: \)\@<=[0-9a-f]\{4,}$/
  syn match plugTag /(tag: [^)]\+)/
  syn match plugInstall /\(^+ \)\@<=[^:]*/
  syn match plugUpdate /\(^* \)\@<=[^:]*/
  syn match plugCommit /^  \X*[0-9a-f]\{7} .*/ contains=plugRelDate,plugEdge,plugTag
  syn match plugEdge /^  \X\+$/
  syn match plugEdge /^  \X*/ contained nextgroup=plugSha
  syn match plugSha /[0-9a-f]\{7}/ contained
  syn match plugRelDate /([^)]*)$/ contained
  syn match plugNotLoaded /(not loaded)$/
  syn match plugError /^x.*/
  syn match plugH2 /^.*:\n-\+$/
  syn keyword Function PlugInstall PlugStatus PlugUpdate PlugClean
  hi def link plug1       Title
  hi def link plug2       Repeat
  hi def link plugH2      Type
  hi def link plugX       Exception
  hi def link plugBracket Structure
  hi def link plugNumber  Number

  hi def link plugDash    Special
  hi def link plugPlus    Constant
  hi def link plugStar    Boolean

  hi def link plugMessage Function
  hi def link plugName    Label
  hi def link plugInstall Function
  hi def link plugUpdate  Type

  hi def link plugError   Error
  hi def link plugRelDate Comment
  hi def link plugEdge    PreProc
  hi def link plugSha     Identifier
  hi def link plugTag     Constant

  hi def link plugNotLoaded Comment
endfunction

function! s:lpad(str, len)
  return a:str . repeat(' ', a:len - len(a:str))
endfunction

function! s:lines(msg)
  return split(a:msg, "[\r\n]")
endfunction

function! s:lastline(msg)
  return get(s:lines(a:msg), -1, '')
endfunction

function! s:new_window()
  execute get(g:, 'plug_window', 'vertical topleft new')
endfunction

function! s:plug_window_exists()
  let buflist = tabpagebuflist(s:plug_tab)
  return !empty(buflist) && index(buflist, s:plug_buf) >= 0
endfunction

function! s:switch_in()
  if !s:plug_window_exists()
    return 0
  endif

  if winbufnr(0) != s:plug_buf
    let s:pos = [tabpagenr(), winnr(), winsaveview()]
    execute 'normal!' s:plug_tab.'gt'
    let winnr = bufwinnr(s:plug_buf)
    execute winnr.'wincmd w'
    call add(s:pos, winsaveview())
  else
    let s:pos = [winsaveview()]
  endif

  setlocal modifiable
  return 1
endfunction

function! s:switch_out(...)
  call winrestview(s:pos[-1])
  setlocal nomodifiable
  if a:0 > 0
    execute a:1
  endif

  if len(s:pos) > 1
    execute 'normal!' s:pos[0].'gt'
    execute s:pos[1] 'wincmd w'
    call winrestview(s:pos[2])
  endif
endfunction

function! s:finish_bindings()
  nnoremap <silent> <buffer> R  :call <SID>retry()<cr>
  nnoremap <silent> <buffer> D  :PlugDiff<cr>
  nnoremap <silent> <buffer> S  :PlugStatus<cr>
  nnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
  xnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
  nnoremap <silent> <buffer> ]] :silent! call <SID>section('')<cr>
  nnoremap <silent> <buffer> [[ :silent! call <SID>section('b')<cr>
endfunction

function! s:prepare(...)
  if empty(getcwd())
    throw 'Invalid current working directory. Cannot proceed.'
  endif

  call s:job_abort()
  if s:switch_in()
    normal q
  endif

  call s:new_window()
  nnoremap <silent> <buffer> q  :if b:plug_preview==1<bar>pc<bar>endif<bar>bd<cr>
  if a:0 == 0
    call s:finish_bindings()
  endif
  let b:plug_preview = -1
  let s:plug_tab = tabpagenr()
  let s:plug_buf = winbufnr(0)
  call s:assign_name()

  silent! unmap <buffer> <cr>
  silent! unmap <buffer> L
  silent! unmap <buffer> o
  silent! unmap <buffer> X
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline modifiable
  setf vim-plug
  if exists('g:syntax_on')
    call s:syntax()
  endif
endfunction

function! s:assign_name()
  " Assign buffer name
  let prefix = '[Plugins]'
  let name   = prefix
  let idx    = 2
  while bufexists(name)
    let name = printf('%s (%s)', prefix, idx)
    let idx = idx + 1
  endwhile
  silent! execute 'f' fnameescape(name)
endfunction

function! s:chsh(swap)
  let prev = [&shell, &shellredir]
  if !s:is_win && a:swap
    set shell=sh shellredir=>%s\ 2>&1
  endif
  return prev
endfunction

function! s:bang(cmd, ...)
  try
    let [sh, shrd] = s:chsh(a:0)
    " FIXME: Escaping is incomplete. We could use shellescape with eval,
    "        but it won't work on Windows.
    let cmd = a:0 ? s:with_cd(a:cmd, a:1) : a:cmd
    let g:_plug_bang = '!'.escape(cmd, '#!%')
    execute "normal! :execute g:_plug_bang\<cr>\<cr>"
  finally
    unlet g:_plug_bang
    let [&shell, &shellredir] = [sh, shrd]
  endtry
  return v:shell_error ? 'Exit status: ' . v:shell_error : ''
endfunction

function! s:regress_bar()
  let bar = substitute(getline(2)[1:-2], '.*\zs=', 'x', '')
  call s:progress_bar(2, bar, len(bar))
endfunction

function! s:is_updated(dir)
  return !empty(s:system_chomp('git log --pretty=format:"%h" "HEAD...HEAD@{1}"', a:dir))
endfunction

function! s:do(pull, force, todo)
  for [name, spec] in items(a:todo)
    if !isdirectory(spec.dir)
      continue
    endif
    let installed = has_key(s:update.new, name)
    let updated = installed ? 0 :
      \ (a:pull && index(s:update.errors, name) < 0 && s:is_updated(spec.dir))
    if a:force || installed || updated
      execute 'cd' s:esc(spec.dir)
      call append(3, '- Post-update hook for '. name .' ... ')
      let error = ''
      let type = type(spec.do)
      if type == s:TYPE.string
        let error = s:bang(spec.do)
      elseif type == s:TYPE.funcref
        try
          let status = installed ? 'installed' : (updated ? 'updated' : 'unchanged')
          call spec.do({ 'name': name, 'status': status, 'force': a:force })
        catch
          let error = v:exception
        endtry
      else
        let error = 'Invalid hook type'
      endif
      call setline(4, empty(error) ? (getline(4) . 'OK')
                                 \ : ('x' . getline(4)[1:] . error))
      if !empty(error)
        call add(s:update.errors, name)
        call s:regress_bar()
      endif
      cd -
    endif
  endfor
endfunction

function! s:hash_match(a, b)
  return stridx(a:a, a:b) == 0 || stridx(a:b, a:a) == 0
endfunction

function! s:checkout(spec)
  let sha = a:spec.commit
  let output = s:system('git rev-parse HEAD', a:spec.dir)
  if !v:shell_error && !s:hash_match(sha, s:lines(output)[0])
    let output = s:system(
          \ 'git fetch --depth 999999 && git checkout '.s:esc(sha), a:spec.dir)
  endif
  return output
endfunction

function! s:finish(pull)
  let new_frozen = len(filter(keys(s:update.new), 'g:plugs[v:val].frozen'))
  if new_frozen
    let s = new_frozen > 1 ? 's' : ''
    call append(3, printf('- Installed %d frozen plugin%s', new_frozen, s))
  endif
  call append(3, '- Finishing ... ') | 4
  redraw
  call plug#helptags()
  call plug#end()
  call setline(4, getline(4) . 'Done!')
  redraw
  let msgs = []
  if !empty(s:update.errors)
    call add(msgs, "Press 'R' to retry.")
  endif
  if a:pull && len(s:update.new) < len(filter(getline(5, '$'),
                \ "v:val =~ '^- ' && stridx(v:val, 'Already up-to-date') < 0"))
    call add(msgs, "Press 'D' to see the updated changes.")
  endif
  echo join(msgs, ' ')
  call s:finish_bindings()
endfunction

function! s:retry()
  if empty(s:update.errors)
    return
  endif
  echo
  call s:update_impl(s:update.pull, s:update.force,
        \ extend(copy(s:update.errors), [s:update.threads]))
endfunction

function! s:is_managed(name)
  return has_key(g:plugs[a:name], 'uri')
endfunction

function! s:names(...)
  return sort(filter(keys(g:plugs), 'stridx(v:val, a:1) == 0 && s:is_managed(v:val)'))
endfunction

function! s:check_ruby()
  silent! ruby require 'thread'; VIM::command("let g:plug_ruby = '#{RUBY_VERSION}'")
  if !exists('g:plug_ruby')
    redraw!
    return s:warn('echom', 'Warning: Ruby interface is broken')
  endif
  let ruby_version = split(g:plug_ruby, '\.')
  unlet g:plug_ruby
  return s:version_requirement(ruby_version, [1, 8, 7])
endfunction

function! s:update_impl(pull, force, args) abort
  let args = copy(a:args)
  let threads = (len(args) > 0 && args[-1] =~ '^[1-9][0-9]*$') ?
                  \ remove(args, -1) : get(g:, 'plug_threads', 16)

  let managed = filter(copy(g:plugs), 's:is_managed(v:key)')
  let todo = empty(args) ? filter(managed, '!v:val.frozen || !isdirectory(v:val.dir)') :
                         \ filter(managed, 'index(args, v:key) >= 0')

  if empty(todo)
    return s:warn('echo', 'No plugin to '. (a:pull ? 'update' : 'install'))
  endif

  if !s:is_win && s:git_version_requirement(2, 3)
    let s:git_terminal_prompt = exists('$GIT_TERMINAL_PROMPT') ? $GIT_TERMINAL_PROMPT : ''
    let $GIT_TERMINAL_PROMPT = 0
    for plug in values(todo)
      let plug.uri = substitute(plug.uri,
            \ '^https://git::@github\.com', 'https://github.com', '')
    endfor
  endif

  if !isdirectory(g:plug_home)
    try
      call mkdir(g:plug_home, 'p')
    catch
      return s:err(printf('Invalid plug directory: %s. '.
              \ 'Try to call plug#begin with a valid directory', g:plug_home))
    endtry
  endif

  if has('nvim') && !exists('*jobwait') && threads > 1
    call s:warn('echom', '[vim-plug] Update Neovim for parallel installer')
  endif

  let python = (has('python') || has('python3')) && (!s:nvim || has('vim_starting'))
  let ruby = has('ruby') && !s:nvim && (v:version >= 703 || v:version == 702 && has('patch374')) && !(s:is_win && has('gui_running')) && s:check_ruby()

  let s:update = {
    \ 'start':   reltime(),
    \ 'all':     todo,
    \ 'todo':    copy(todo),
    \ 'errors':  [],
    \ 'pull':    a:pull,
    \ 'force':   a:force,
    \ 'new':     {},
    \ 'threads': (python || ruby || s:nvim) ? min([len(todo), threads]) : 1,
    \ 'bar':     '',
    \ 'fin':     0
  \ }

  call s:prepare(1)
  call append(0, ['', ''])
  normal! 2G
  silent! redraw

  let s:clone_opt = get(g:, 'plug_shallow', 1) ?
        \ '--depth 1' . (s:git_version_requirement(1, 7, 10) ? ' --no-single-branch' : '') : ''

  " Python version requirement (>= 2.7)
  if python && !has('python3') && !ruby && !s:nvim && s:update.threads > 1
    redir => pyv
    silent python import platform; print platform.python_version()
    redir END
    let python = s:version_requirement(
          \ map(split(split(pyv)[0], '\.'), 'str2nr(v:val)'), [2, 6])
  endif

  if (python || ruby) && s:update.threads > 1
    try
      let imd = &imd
      if s:mac_gui
        set noimd
      endif
      if ruby
        call s:update_ruby()
      else
        call s:update_python()
      endif
    catch
      let lines = getline(4, '$')
      let printed = {}
      silent! 4,$d _
      for line in lines
        let name = s:extract_name(line, '.', '')
        if empty(name) || !has_key(printed, name)
          call append('$', line)
          if !empty(name)
            let printed[name] = 1
            if line[0] == 'x' && index(s:update.errors, name) < 0
              call add(s:update.errors, name)
            end
          endif
        endif
      endfor
    finally
      let &imd = imd
      call s:update_finish()
    endtry
  else
    call s:update_vim()
  endif
endfunction

function! s:log4(name, msg)
  call setline(4, printf('- %s (%s)', a:msg, a:name))
  redraw
endfunction

function! s:update_finish()
  if exists('s:git_terminal_prompt')
    let $GIT_TERMINAL_PROMPT = s:git_terminal_prompt
  endif
  if s:switch_in()
    call append(3, '- Updating ...') | 4
    for [name, spec] in items(filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && (s:update.force || s:update.pull || has_key(s:update.new, v:key))'))
      let pos = s:logpos(name)
      if !pos
        continue
      endif
      if has_key(spec, 'commit')
        call s:log4(name, 'Checking out '.spec.commit)
        let out = s:checkout(spec)
      elseif has_key(spec, 'tag')
        let tag = spec.tag
        if tag =~ '\*'
          let tags = s:lines(s:system('git tag --list '.string(tag).' --sort -version:refname 2>&1', spec.dir))
          if !v:shell_error && !empty(tags)
            let tag = tags[0]
            call s:log4(name, printf('Latest tag for %s -> %s', spec.tag, tag))
            call append(3, '')
          endif
        endif
        call s:log4(name, 'Checking out '.tag)
        let out = s:system('git checkout -q '.s:esc(tag).' 2>&1', spec.dir)
      else
        let branch = s:esc(get(spec, 'branch', 'master'))
        call s:log4(name, 'Merging origin/'.branch)
        let out = s:system('git checkout -q '.branch.' 2>&1'
              \. (has_key(s:update.new, name) ? '' : ('&& git merge --ff-only origin/'.branch.' 2>&1')), spec.dir)
      endif
      if !v:shell_error && filereadable(spec.dir.'/.gitmodules') &&
            \ (s:update.force || has_key(s:update.new, name) || s:is_updated(spec.dir))
        call s:log4(name, 'Updating submodules. This may take a while.')
        let out .= s:bang('git submodule update --init --recursive 2>&1', spec.dir)
      endif
      let msg = printf('%s %s: %s', v:shell_error ? 'x': '-', name, s:lastline(out))
      if v:shell_error
        call add(s:update.errors, name)
        call s:regress_bar()
        execute pos 'd _'
        call append(4, msg) | 4
      elseif !empty(out)
        call setline(pos, msg)
      endif
      redraw
    endfor
    4 d _
    call s:do(s:update.pull, s:update.force, filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && has_key(v:val, "do")'))
    call s:finish(s:update.pull)
    call setline(1, 'Updated. Elapsed time: ' . split(reltimestr(reltime(s:update.start)))[0] . ' sec.')
    call s:switch_out('normal! gg')
  endif
endfunction

function! s:job_abort()
  if !s:nvim || !exists('s:jobs')
    return
  endif

  for [name, j] in items(s:jobs)
    silent! call jobstop(j.jobid)
    if j.new
      call s:system('rm -rf ' . s:shellesc(g:plugs[name].dir))
    endif
  endfor
  let s:jobs = {}
endfunction

" When a:event == 'stdout', data = list of strings
" When a:event == 'exit', data = returncode
function! s:job_handler(job_id, data, event) abort
  if !s:plug_window_exists() " plug window closed
    return s:job_abort()
  endif

  if a:event == 'stdout'
    let complete = empty(a:data[-1])
    let lines = map(filter(a:data, 'len(v:val) > 0'), 'split(v:val, "[\r\n]")[-1]')
    call extend(self.lines, lines)
    let self.result = join(self.lines, "\n")
    if !complete
      call remove(self.lines, -1)
    endif
    " To reduce the number of buffer updates
    let self.tick = get(self, 'tick', -1) + 1
    if self.tick % len(s:jobs) == 0
      call s:log(self.new ? '+' : '*', self.name, self.result)
    endif
  elseif a:event == 'exit'
    let self.running = 0
    if a:data != 0
      let self.error = 1
    endif
    call s:reap(self.name)
    call s:tick()
  endif
endfunction

function! s:spawn(name, cmd, opts)
  let job = { 'name': a:name, 'running': 1, 'error': 0, 'lines': [], 'result': '',
            \ 'new': get(a:opts, 'new', 0),
            \ 'on_stdout': function('s:job_handler'),
            \ 'on_exit' : function('s:job_handler'),
            \ }
  let s:jobs[a:name] = job

  if s:nvim
    let argv = [ 'sh', '-c',
               \ (has_key(a:opts, 'dir') ? s:with_cd(a:cmd, a:opts.dir) : a:cmd) ]
   