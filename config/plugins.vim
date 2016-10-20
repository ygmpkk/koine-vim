" vim: set ft=vim;

function! Cond(cond, ...)
    let opts = get(a:000, 0, {})
    return a:cond ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction

call plug#begin('~/.vim/bundle')

""""""
" 通用
""""""

" 启动器
Plug 'mhinz/vim-startify'
Plug 'scrooloose/nerdcommenter'
" 目录树
Plug 'scrooloose/nerdtree', {'on': 'NERDTreeToggle'}
" 眼球追踪
Plug 'easymotion/vim-easymotion'
" 等号缩进
Plug 'junegunn/vim-easy-align'
" 多焦点选择
Plug 'terryma/vim-multiple-cursors'
" 搜索
Plug 'vim-ctrlspace/vim-ctrlspace'
" 状态栏
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" 补全和替换
Plug 'Raimondi/delimitMate'
" 有道字典
Plug 'ianva/vim-youdao-translater'
" 自动格式化
Plug 'Chiel92/vim-autoformat', {'on': 'Autoformat'}
" 打开文件最后的位置
Plug 'dietsche/vim-lastplace'
" Ansi文档查看
Plug 'powerman/vim-plugin-AnsiEsc'
" 任务
" Plug 'davidoc/taskpaper.vim'
Plug 'xolox/vim-misc'
Plug 'xolox/vim-notes'
" Font
Plug 'powerline/fonts'
" Color
Plug 'flazz/vim-colorschemes'
" Search
Plug 'rking/ag.vim'
" Files
" Plug 'vim-scripts/FuzzyFinder'
""""""
" 写作
""""""
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown', {'for': 'markdown'}
Plug 'jszakmeister/markdown2ctags'
Plug 'junegunn/goyo.vim'
Plug 'amix/vim-zenroom2'
Plug 'IN3D/vim-raml', {'for': 'raml'}
Plug 'leshill/vim-json', {'for': 'json'}

""""""
" 编程
""""""
Plug 'floobits/floobits-neovim', Cond(has('nvim'), { 'do': function('hooks#remote') })
Plug 'ygmpkk/vim-header-comment'
Plug 'janko-m/vim-test'
Plug 'jrosiek/vim-mark'
Plug 'kien/rainbow_parentheses.vim'
" Command
Plug 'tpope/vim-dispatch'
" 标签
Plug 'majutsushi/tagbar'
" Dash配套
Plug 'rizzatti/funcoo.vim'
" Dash搜索
Plug 'rizzatti/dash.vim'
" 语法分析
Plug 'scrooloose/syntastic'
" 补全
Plug 'tpope/vim-surround'
" Git插件
Plug 'tpope/vim-fugitive'
" Git修改指示
Plug 'airblade/vim-gitgutter'
" Git撤销树
Plug 'vim-scripts/Gundo'

" 代码提示
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
if has('nvim')
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    Plug 'carlitux/deoplete-ternjs'
    Plug 'landaire/deoplete-swift'
    Plug 'awetzel/elixir.nvim'
    Plug 'zchee/deoplete-go'
    Plug 'zchee/deoplete-jedi'
    Plug 'steelsojka/deoplete-flow'
else
    Plug 'Valloric/YouCompleteMe', { 'do': './install.py'}
endif

" Golang
Plug 'fatih/vim-go', {'for': 'go', 'tag': '*'}
Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }
" Erlang
Plug 'vim-erlang/vim-erlang-runtime', {'for': 'erlang'}
Plug 'vim-erlang/vim-erlang-compiler', {'for': 'erlang'}
Plug 'vim-erlang/vim-erlang-omnicomplete', {'for': 'erlang'}
Plug 'vim-erlang/vim-erlang-tags', {'for': 'erlang'}
Plug 'ten0s/syntaxerl', {'for': 'erlang'}
" Elixir
Plug 'elixir-lang/vim-elixir', {'for': 'elixir'}
Plug 'thinca/vim-ref', {'for': 'elixir'}
" 前端
Plug 'editorconfig/editorconfig-vim'
" Plug 'ruanyl/vim-fixmyjs', {'on': 'Fixmyjs'}
" Plug 'MattesGroeger/vim-bookmarks'
" Javascript
Plug 'ternjs/tern_for_vim', {'do': 'npm install', 'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'flowtype/vim-flow', {'do': 'npm install', 'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'pangloss/vim-javascript', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'othree/yajs.vim', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'othree/javascript-libraries-syntax.vim', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'othree/jsdoc-syntax.vim', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'othree/jspc.vim', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'isRuslan/vim-es6', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'jelera/vim-javascript-syntax', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'kchmck/vim-coffee-script', {'for': 'coffee'}
Plug 'heavenshell/vim-jsdoc', {'for': ['javascript', 'jsx', 'javascript.jsx']}
Plug 'mxw/vim-jsx', {'for': ['jsx', 'javascript.jsx']}
" Html
Plug 'othree/html5.vim', {'for': 'html'}
Plug 'docunext/closetag.vim', {'for': ['html', 'jsx', 'javascript.jsx']}
Plug 'mattn/emmet-vim', {'for': 'html'}
" Css
Plug 'groenewege/vim-less', {'for': 'less'}
Plug 'hail2u/vim-css3-syntax', {'for': ['css', 'less', 'sass', 'scss']}
" Elm
Plug 'elmcast/elm-vim', {'for': 'elm'}
" Ember
Plug 'mustache/vim-mustache-handlebars', {'for': 'html.handlebars'}
Plug 'joukevandermaas/vim-ember-hbs', {'for': 'html.handlebars'}
" Python
Plug 'klen/python-mode', {'for': 'python'}

""""""
" 其它
""""""

" Record worktime
Plug 'wakatime/vim-wakatime'

" FlowChart
Plug 'vim-scripts/DrawIt'

" Plug 'vim-scripts/L9'
" " API Blurprint
" Plug 'kylef/apiblueprint.vim'
" " Shell
" Plug 'Shougo/vimproc.vim'
" Plug 'Shougo/vimshell.vim'
call plug#end()
" test
