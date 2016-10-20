" vim:set ft=vim;

augroup General
    autocmd!

    " 最后打开的位置
    let g:lastplace_ignore = "gitcommit,svn,hg,hgcommit,asciidoc"

    " 文件导航
    let NERDTreeIgnore=['\.pyc','\~$','\.swp']
    let NERDTreeRespectWildIgnore=1
    let g:NERDTreeIndicatorMapCustom = {
                \ "Modified"  : "✹",
                \ "Staged"    : "✚",
                \ "Untracked" : "✭",
                \ "Renamed"   : "➜",
                \ "Unmerged"  : "═",
                \ "Deleted"   : "✖",
                \ "Dirty"     : "✗",
                \ "Clean"     : "✔︎",
                \ "Unknown"   : "?"
                \ }

    " 注释
    let g:NERDSpaceDelims=1

    " 默认关闭参考线
    let g:indentLine_enabled = 0

    " 状态条
    let g:airline_powerline_fonts = 1
    let g:Powerline_symbols = 'fancy'
    let g:airline_theme='base16_atelierheath'
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#buffer_nr_show = 1
    let g:airline_exclude_preview = 1

    " 眼球追踪
    let g:EasyMotion_smartcase = 1
    let g:EasyMotion_startofline = 0
    " keep cursor colum when JK motion

    " Gundo 插件
    let g:gundo_width = 60
    let g:gundo_preview_height = 40
    let g:gundo_right = 1

    " 高亮演示匹配括号
    let g:rbpt_colorpairs = [
                \ [158, '#00ceb3'],
                \ [081, '#00a3ff'],
                \ [214, '#ff8d00'],
                \ [123, '#3fffc9'],
                \ [045, '#29b9ec'],
                \ [190, '#bfec29'],
                \ [208, '#ffad00'],
                \ [117, '#48bde0'],
                \ ]

    let g:rbpt_max = 8
    let g:rbpt_loadcmd_toggle = 0

    au VimEnter * RainbowParenthesesToggle
    au Syntax * RainbowParenthesesLoadRound
    au Syntax c,cpp,go,h,java,python,javascript,scala,coffee RainbowParenthesesLoadSquare
    au Syntax c,cpp,go,h,java,python,javascript,scala,coffee,scss  RainbowParenthesesLoadBraces
augroup END

augroup AutoMkdir
    autocmd!
    autocmd  BufNewFile  *  :call EnsureDirExists()
augroup END

augroup AutoHeader
    autocmd!
    autocmd BufNewFile *.go,*.sh,*.py,*.rb exec ":call SetTitle()" 

    func! SetTitle() 

        if expand("%:e") == 'go'
            call setline(1,"package ".expand("%:p:h:t"))
            call append(line("."), "")

        elseif &filetype == 'sh' 
            call setline(1,"\#!/bin/bash") 
            call append(line("."), "") 

        elseif &filetype == 'python'
            call setline(1,"#!/usr/bin/env python")
            call append(line("."),"# -*- coding: utf-8 -*-")
            call append(line(".")+1, "") 

        elseif &filetype == 'ruby'
            call setline(1,"#!/usr/bin/env ruby")
            call append(line("."),"# encoding: utf-8")
            call append(line(".")+1, "")

        endif

        autocmd BufNewFile * normal G

    endfunc 

augroup END

augroup CtrlSpace
    autocmd!
    " 文件搜索
    hi link CtrlSpaceNormal   Normal
    hi link CtrlSpaceSelected CursorLine
    hi link CtrlSpaceSearch   Search
    hi link CtrlSpaceStatus   Constant
    let g:CtrlSpaceUseUnicode = 1
    let g:CtrlSpaceProjectRootMarkers = [
                \ ".git",
                \ ".hg",
                \ ".svn",
                \ ".bzr",
                \ "_darcs",
                \ "CVS",
                \ "node_modules",
                \ "bower_components",
                \ "vendor"
                \ ]
    let g:CtrlSpaceIgnoredFiles = '\v(tmp|temp|node_modules|bower_components|\.\*pyc)[\/]'
    let g:CtrlSpaceSearchTiming = 500
    if executable("ag")
        let g:CtrlSpaceGlobCommand = 'ag -l --nocolor -g ""'
    endif
augroup END

augroup Startify
    autocmd!
    let g:startify_skiplist = [
                \ 'COMMIT_EDITMSG',
                \ 'bundle/.*/doc',
                \ 'node_modules/*',
                \ 'bower_components/*',
                \ ]

    if filereadable(expand("~/.startify_bookmarks"))
        source ~/.startify_bookmarks
    endif 

    let g:startify_transformations = [
                \ ['.*vimrc$', 'vimrc'],
                \ ]

    " let g:startify_list_order = ['files', 'dir', 'bookmarks', 'sessions']
    let g:startify_enable_speciali = 0
    let g:startify_change_to_dir = 1
    let g:startify_change_to_vcs_root = 1
    let g:startify_session_autoload = 0
    let g:startify_session_delete_buffers = 1
    let g:startify_session_persistence = 1
    let g:startify_update_oldfiles = 1
    " 需要 base 的 ~/.profile 或 zsh 的 ~/.zprofile
    let g:startify_use_env = 1
    let g:startify_files_number = 20
augroup END

augroup Tagbar
    autocmd!
    " tagbar
    let g:tagbar_type_go = {
                \ 'ctagstype' : 'go',
                \ 'kinds'     : [
                \ 'p:package',
                \ 'i:imports:1',
                \ 'c:constants',
                \ 'v:variables',
                \ 't:types',
                \ 'n:interfaces',
                \ 'w:fields',
                \ 'e:embedded',
                \ 'm:methods',
                \ 'r:constructor',
                \ 'f:functions'
                \ ],
                \ 'sro' : '.',
                \ 'kind2scope' : {
                \ 't' : 'ctype',
                \ 'n' : 'ntype'
                \ },
                \ 'scope2kind' : {
                \ 'ctype' : 't',
                \ 'ntype' : 'n'
                \ },
                \ 'ctagsbin'  : 'gotags',
                \ 'ctagsargs' : '-sort -silent'
                \ }

    let g:tagbar_type_elixir = {
                \ 'ctagstype' : 'elixir',
                \ 'kinds' : [
                \ 'f:functions',
                \ 'functions:functions',
                \ 'c:callbacks',
                \ 'd:delegates',
                \ 'e:exceptions',
                \ 'i:implementations',
                \ 'a:macros',
                \ 'o:operators',
                \ 'm:modules',
                \ 'p:protocols',
                \ 'r:records'
                \ ],
                \ 'sro': '.',
                \ 'kind2scope': {
                \ 'm': 'modules'
                \ },
                \ 'scope2kind': {
                \ 'modules': 'm'
                \ }
                \ }

    let g:tagbar_type_markdown = {
                \ 'ctagstype' : 'markdown',
                \ 'ctagsbin' : '~/.vim/bundle/markdown2ctags/markdown2ctags.py',
                \ 'ctagsargs' : '-f - --sort=yes',
                \ 'kinds' : [
                \ 's:sections',
                \ 'i:images'
                \ ],
                \ 'sro' : '|',
                \ 'kind2scope' : {
                \ 's' : 'section',
                \ },
                \ 'sort': 0,
                \ }
augroup END

augroup Completion
    autocmd!
    if has('nvim')
        let g:deoplete#enable_at_startup = 1
        let g:tern_request_timeout = 1
        " This do disable full signature type on autocomplete
        let g:tern_show_signature_in_pum = '0'
    else
        " let g:ycm_python_binary_path = '/usr/local/opt/python/bin/python2.7'
        " let g:ycm_collect_identifiers_from_tags_files = 1
        " let g:ycm_seed_identifiers_with_syntax = 1
        " let g:ycm_confirm_extra_conf = 0
        " let g:ycm_min_num_of_chars_for_completion = 5
        " let g:ycm_auto_trigger = 1
        " let g:ycm_path_to_python_interpreter = '/usr/bin/python2'
        " let g:ycm_show_diagnostics_ui = 0
        let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
        let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
        let g:ycm_filetype_blacklist = {
                    \ 'elixir' : 1,
                    \ 'tagbar' : 1,
                    \ 'qf' : 1,
                    \ 'notes' : 1,
                    \ 'markdown' : 1,
                    \ 'unite' : 1,
                    \ 'text' : 1,
                    \ 'vimwiki' : 1,
                    \ 'pandoc' : 1,
                    \ 'infolog' : 1,
                    \ 'mail' : 1
                    \}
        " let g:ycm_filetype_whitelist = { 
        "             \ 'go': 1 ,
        "             \ 'python': 1 
        "             \ }
        " 代码提示关键字
        let g:ycm_semantic_triggers =  {
                    \   'c' : ['->', '.'],
                    \   'objc' : ['->', '.', 're!\[[_a-zA-Z]+\w*\s', 're!^\s*[^\W\d]\w*\s',
                    \             're!\[.*\]\s'],
                    \   'ocaml' : ['.', '#'],
                    \   'cpp,objcpp' : ['->', '.', '::'],
                    \   'perl' : ['->'],
                    \   'php' : ['->', '::'],
                    \   'cs,java,typescript,d,python,perl6,scala,vb,go,elm' : ['.'],
                    \   'javascript': ['.', 're!(?=[a-zA-Z]{3,4})'],
                    \   'ruby' : ['.', '::'],
                    \   'lua' : ['.', ':'],
                    \   'erlang' : [':'],
                    \ }
    endif
augroup END

augroup Syntastic
    autocmd!
    "syntastic相关
    " set statusline+=%#warningmsg#
    " set statusline+=%{SyntasticStatuslineFlag()}
    " set statusline+=%*
    let g:syntastic_quiet_messages = {'level': 'warnings'}
    let g:syntastic_check_on_open=0
    let g:syntastic_error_symbol='✗'
    let g:syntastic_warning_symbol='⚠'

    let g:syntastic_python_checkers=['pylint']
    let g:syntastic_php_checkers=['php', 'phpcs', 'phpmd']
    let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
    " let g:syntastic_javascript_checkers = ['eslint', 'jshint', 'jslint']
    let g:syntastic_javascript_checkers = ['eslint']
    let g:syntastic_json_checkers = ['jsonlint']
    let g:syntastic_mode_map = { 'mode': 'passive', 
                \ 'active_filetypes': ['python', 'javascript'],
                \ 'passive_filetypes': ['go'] 
                \ }

    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 1
    let g:elm_syntastic_show_warnings = 0
augroup END

augroup UnitTest
    autocmd!
    " let test#strategy = {
    " 			\ 'nearest': 'neovim',
    " 			\ 'file':    'dispatch',
    " 			\ 'suite':   'basic',
    " 			\}
    let test#go#gotest#executable = 'gb test'
augroup END

augroup Frontend
    autocmd!
    " 加载.editorconfig文件的配置
    let g:EditorConfig_core_mode = 'external_command'
    " let g:EditorConfig_verbose = 1

    " Javascript代码检查
    let $JS_CMD='node'
    let g:JSLintHighlightErrorLine = 0

    " frontend
    let g:javascript_enable_domhtmlcss = 1
    let g:javascript_fold = 0
    let g:javascript_conceal_function       = "ƒ"
    let g:javascript_conceal_null           = "ø"
    let g:javascript_conceal_this           = "@"
    let g:javascript_conceal_return         = "⇚"
    let g:javascript_conceal_undefined      = "¿"
    let g:javascript_conceal_NaN            = "ℕ"
    let g:javascript_conceal_prototype      = "¶"
    let g:javascript_conceal_static         = "•"
    let g:javascript_conceal_super          = "Ω"
    let g:javascript_conceal_arrow_function = "⇒"

    " JSDOC
    let g:javascript_plugin_jsdoc = 1
    let g:javascript_plugin_ngdoc = 1
    let g:javascript_plugin_flow = 1

    let g:jsdoc_additional_descriptions = 1
    " let g:jsdoc_input_description = 1
    " let g:jsdoc_allow_input_prompt = 1
    let g:jsdoc_access_descriptions = 0
    let g:jsdoc_return = 1
    " let g:jsdoc_return_type = 1
    let g:jsdoc_return_description = 1
    let g:jsdoc_enable_es6 = 1

    " Html css
    let g:closetag_html_style=1

    let g:tern#command = ["tern"]
    let g:tern#arguments = ["--persistent"]
    let g:flow#autoclose = 1
    let g:flow#qfsize = 0

    " 自动闭合
    autocmd FileType xml,html let b:delimitMate_matchpairs = "(:),[:],{:},<:>"
    " autocmd BufReadPost *.{js,coffee} nnoremap <buffer> K :TernDoc<CR>
    " autocmd FileType javascript setlocal omnifunc=tern#Complete
augroup END

augroup Go
    autocmd!
    " golang
    " let $GOPATH = $HOME."/source/goenv"
    " let g:go_bin_path = $HOME."/source/goenv/bin"
    let go_def_mapping_enabled = 0
    let g:go_disable_autoinstall = 0
    let g:go_highlight_functions = 1
    let g:go_highlight_methods = 1
    let g:go_highlight_structs = 1
    let g:go_highlight_operators = 1
    let g:go_highlight_build_constraints = 1
    " let g:fencview_autodetect=0
    " set rtp+=$GOROOT/github.com/nsf/gocode/vim
    let g:go_fmt_command = "goimports"
    " let g:go_fmt_fail_silently = 1
    " let g:go_fmt_autosave = 1
    " let g:go_play_open_browser = 0
    " let g:go_term_mode = "split"
    " let g:go_term_enabled = 1
    autocmd FileType go set noexpandtab
    autocmd FileType go set foldmethod=indent
augroup END

augroup Elixir
    autocmd!
    " let g:elixir_showerror = 1
    " let g:elixir_autobuild = 1
augroup END

augroup Elm
    autocmd!
    let g:elm_jump_to_error = 0
    " let g:elm_make_output_file = "../dist/elm.js"
    let g:elm_make_show_warnings = 0
    let g:elm_browser_command = ""
    let g:elm_detailed_complete = 1
    let g:elm_format_autosave = 1
    let g:elm_setup_keybindings = 0
    let g:elm_classic_hightlighting = 0
augroup END

augroup React
    autocmd!
    let g:jsx_ext_required = 0
    " let g:jsx_pragma_required = 1
augroup END

augroup Written
    autocmd!
    " Markdown
    autocmd BufNewFile,BufReadPost *.md set filetype=markdown
    autocmd BufRead,BufNewFile *.{md,mdown,mkd,mkdn,markdown,mdwn} map <Leader>p :!/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "%:p"<CR>
    let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']
    " let g:vim_markdown_no_default_key_mappings = 1

    " TaskPaper
    " let g:task_paper_date_format = "%Y-%m-%d %H:%M:%S"
    " let g:task_paper_archive_project = "~/Documents/Notes"

    " Note 插件
    let g:notes_directories = ['~/Documents/Notes', '~/Dropbox/Notes']
    let g:notes_suffix = '.taskpaper'
    " 'no' 'change_title' 'rename_file'
    let g:notes_title_sync = 'rename_file'
    let g:notes_unicode_enabled = 1
    let g:notes_smart_quotes = 1
    let g:notes_word_boundaries = 1
augroup END

augroup Python
    " 代码检查
    let g:pymode_lint_ignore = "E501,E221,E251,W"
    " 错误标识
    let g:pymode_lint_signs = 1
    " let g:pymode_lint_on_fly = 1
    let g:pymode_lint_todo_symbol = '➜'
    let g:pymode_lint_comment_symbol = '✡'
    let g:pymode_lint_visual_symbol = '⎈'
    let g:pymode_lint_error_symbol = '✘'
    let g:pymode_lint_info_symbol = '✪'
    let g:pymode_lint_pyflakes_symbol = '✇'

    let g:pymode_rope_lookup_project = 1
    let g:pymode_rope_completion = 1
    let g:pymode_rope_complete_on_dot = 0
    let g:pymode_rope_completion_bind = '<C-P>'
augroup END

augroup HeaderComment
    let g:header_comment_author = "Timothy Yeh"
    let g:header_comment_copyright = ""
augroup END

" augroup
" augroup END
