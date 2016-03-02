" Description: Open require/@import file
" Author: Asins <asinsimple@gmail.com>
" Last Modified: 2016-03-03 01:39 (+0800)
" License: MIT

" 变量设置 {{{1
if exists('loaded_openRequireFile') || &compatible || v:version < 700
  finish
endif
let loaded_openRequireFile = 1

" 以对应表形式指定项目根目录(project root by map)
"
" let g:OpenRequireFile_By_Map = [
" 	\ $HOME.'/Git/project/src/js',
" 	\ $HOME.'/Git/project/src/css',
" 	\ $HOME.'/Git/projectB/lib',
" 	\ ]
if !exists('g:OpenRequireFile_By_Map') || type(g:OpenRequireFile_By_Map) != 3

  let g:OpenRequireFile_By_Map = []
endif

" 项目版本仓库，数据类型：列表，查找顺序: 靠前者优先
if !exists('g:OpenRequireFile_By_Mark') || type(g:OpenRequireFile_By_Mark) != 3
	let g:OpenRequireFile_By_Mark = ['.git', '.svn', '.hg']
endif
" }}}

" 命令指定 {{{1
command -nargs=* OpenRequireFile call OpenRequireFile(<f-args>)
"}}}

" Mapping {{{1
if !hasmapto('OpenRequireFile')
	nnoremap <silent> <Leader>gf :<C-U>call OpenRequireFile()<CR>
endif
" }}}

" 替换目录分隔符 {{{1
function! <SID>ReplaceSeparator(path, ...)
	if a:0 > 0
		let s:separator = a:1
	else
		let s:separator = has("win32") || has("win64") || has("win95") || has("win16") ? '\' : '/'
	endif

	let extra = ':gs?\v(\\|/)+?'. s:separator .'?'
	return fnamemodify(a:path, extra)
endfunction
" }}}
" 格式化Path {{{1
function! <SID>FormatPath(path, ...)
	" Path统一使用 / 作为目录分隔符
	let s:path = <SID>ReplaceSeparator(a:path, '/')
	" 去除尾部所带的 /
	let s:path = substitute(s:path, '\/\+$', '', '')

	" 1. 默认使用自带后缀
	let s:suffix = fnamemodify(s:path, ':e')
	if s:suffix != ''
		return s:path
	endif


	" 2. 使用当前文件相同的后缀
	let s:suffix = expand('%:e')
	if s:suffix != ''
		return s:path. '.' .s:suffix
	endif

	" 3. 以上不满足则认为文件无后缀
	return s:path
endfunction
" }}}
" 从光标处获取文件路径(补全后缀) {{{1
" 优先级 require < @import < <sWORD>相对URL
function! <SID>GetCursorFilePath()
	let lineStr = getline('.')

	" 1. Js/Tpl/txt/... 识别：
	"     require ( 'xx/oo');
	"     require("xx/oo.txt")
	"  以下正则为 \v.*require\s*\(("|')([^\1]+)\1\);?.* 单引号加入报错固加链接符 TODO
	let requirePath = substitute(lineStr, '\v.*require\s*\(("|' . "'" . ')([^\1]+)\1\);?.*', '\2', '')
	if lineStr != requirePath
		" echo '2.1 '. requirePath
		return <SID>FormatPath(requirePath)
	endif

	" 2. CSS/Less/Scss 引入方式 识别：
	"     @import 'xx/oo.less'
	"     @import "./xxx/oo";
	"     @import '../xx/oo.css'
	"  以下正则为 \v\@import\s+("|')([^\1]+)\1; 单引号加入报错固加链接符 TODO
	let importPath = substitute(lineStr, '\v\@import\s+("|' ."'" .')([^\1]+)\1;?', '\2', '')
	if lineStr != importPath
		" echo '2.2 '. importPath
		return <SID>FormatPath(importPath)
	endif

	" 3. 无规则的文件引入，如css中的图片引入 识别：
	"     'oo/xx'
	"     "../oo/xx"
	let cword = expand('<cWORD>')
	let otherPath = substitute(cword, '\v.*("|' . "'" . ')([^\1]+)\1.*', '\2', '')
	if cword != otherPath
		" echo '2.3 '.otherPath
		return <SID>FormatPath(otherPath)
	endif
	let otherPath = substitute(getline('.'), '\v.*("|' . "'" . ')([^\1]+)\1.*', '\2', '')
	if lineStr != otherPath
		" echo '2.4 '.otherPath
		return <SID>FormatPath(otherPath)
	endif

	return ''
endfunction
" }}}
" 获取项目目录 {{{1
function <SID>GetFilesProjectRootPath(filePath)
	let curFilePath = fnamemodify(a:filePath, ':p:h')

	" 1. 基于Map查找项目Root TODO 更好的实现方式
	let findRoot4Map = curFilePath
	while len(findRoot4Map) > 0
		" let s:pathForMap = get(g:OpenRequireFile_By_Map, findRoot4Map, '')
		" echo '3.1 '.findRoot4Map
		" if len(s:pathForMap) > 0 " Map中存在
			" return findRoot4Map.s:pathForMap
		" endif
		let s:arrIndex = index(g:OpenRequireFile_By_Map, findRoot4Map)
		" echo '3.1 '.findRoot4Map . '  '. s:arrIndex. ' > -1 则Map中存在'
		if s:arrIndex > -1 " Map中存在
			return g:OpenRequireFile_By_Map[s:arrIndex]
		endif

		let s:temp = fnamemodify(findRoot4Map, ':p:h:h')
		if(findRoot4Map == s:temp) " 无上层目录
			break
		else
			let findRoot4Map = s:temp
		endif
	endwhile

	" " 2. 基于版本仓库目录定位项目Root
	" for dirPath in g:OpenRequireFile_By_Mark
		" let verPath = finddir(dirPath, curFilePath.';') " 向上查找
		" " echo '3.2 '.verPath
		" if verPath != ''
			" let verPath = fnamemodify(verPath, ':p:h:h')
			" let srcPath = finddir('src', verPath)
			" return srcPath != '' ? srcPath : verPath
		" endif
	" endfor
	" 2. 基于文件或目录标记定位项目Root目录
	for markStr in g:OpenRequireFile_By_Mark
		" 向上查找目录
		let pathByDir = finddir(markStr, curFilePath.';')
		if pathByDir != ''
			let pathByDir = fnamemodify(pathByDir, ':p:h:h')
			" 如果存在src子目录，则Root为src目录
			let srcInPath = finddir('src', pathByDir)
			return srcInPath != '' ? srcInPath : pathByDir
		endif
		" 向上查找文件
		let pathByFile = findfile(markStr, curFilePath.';')
		if pathByFile != ''
			let pathByFile fnamemodify(pathByFile, ':p:h:h')
			" 如果存在src子目录，则Root为src目录
			let srcInPath = finddir('src', pathByFile)
			return srcInPath != '' ? srcInPath : pathByDir
		endif
	endfor

	echohl WarningMsg
	echomsg 'OpenRequireFile.vim: No find project directory. you can set it in `g:OpenRequireFile_By_Map`'
	echohl None
	return ''
endfunction
" }}}

" 入口函数 {{{1
function! OpenRequireFile(...)
	if a:0 == 0
		let filePath = <SID>GetCursorFilePath()
	else
		let filePath = <SID>FormatPath(a:1)
	endif

	" ./file or  ../file
	if strridx(filePath, './') == 0 || strridx(filePath, '../') == 0
		let fullPath = fnamemodify(filePath, ':p')
	else " 绝对引入
		" echo '1.1 绝对引入'
		let prefpath = <SID>GetFilesProjectRootPath('<sfile>')
		let fullPath = prefpath .'/'. filePath
	endif
	let fullPath = <SID>ReplaceSeparator(fullPath)
	" echo '0. fullPath = '. fullPath

	if findfile(fullPath) == ''
		echo 'File not exist, Create now: '. fullPath
	endif
	execute ":edit " fullPath
endfunction
" }}}



" Vim Modeline: {{{1
" vim: fdm=marker fmr={{{,}}}  foldcolumn=1
" }}}
