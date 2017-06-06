# openRequireFile.vim

openRequireFile.vim 插件可以用来打开代码中对应文件，特别适合 CommonJs(RequireJs/SeaJs 等） / Less / Sass 等项目中引入子文件。

目前还不支持打开`npm`方式安装的包文件，也就是说 NodeJs 项目还不支持。

## 安装

#### Vundle:

```
Bundle "asins/openRequireFile.vim"
```

#### vim-plug:

```
Plug 'asins/openRequireFile.vim'
```

## 使用

``` vim
" 命令行方式
:OpenRequireFile [path]

" 函数调用方式
:call OpenRequireFile([path])
```

打开 `path` 文件，当未指定参数则打开当前光标处满足**路径规则**的文件

## 映射

`<Leader>gf` 打开当前光标处满足**路径规则**的路径文件

## 路径规则

通过使用特定规则识别出光标所在行的有效路径。支持打开相对 (./xx)、关系路径 (../xx)、绝对路径 (xx/oo) 方式的地址。

注意：绝对地址方式需要先指定项目根目录地址。

### 获取项目目录优先级

 1. Maa 查找方式
 2. 文件或目录标记定位方式

### 取光标位置字符优先级

 1. `require('xx')` 语法
 2. `@import 'oo'` 语法
 3. 无规则文件引入（这种方式是取光标所在字串，所以需要将光标定位在路径内）

### 补全后缀名优先级

 1. 默认使用路径自带后缀
 3. 使用当前文件相同后缀
 4. 以上不满足则认为无文件后缀


## 案例

例 1：当前文件为`~/project/asins/test.js`，并存在`~/project/.git`目录

```js
require('lib/zepto'); // open: ~/project/lib/zepto.js
require("lib/zepto'); // open Error!  " != ' Label mismatch.
require(lib/zepto); // open Error!  need ' or "

// file path: ~/project/src/js/test.js
require("./test.tpl") // open: ~/project/js/test.tpl
// file path: ~/project/src/js/g/nav/test.js
require("../../lib/zepto") // open: ~/project/lib/zepto.js
```

例 2：当前文件为`~/project/src/js/test.js`，存在`~/project/.git`目录，在`vimrc`中设置`let g:OpenRequireFile_By_Map = [$HOME.'/project/src/js']

```js
require('lib/zepto'); // open: ~/project/src/js/lib/zepto.js
```

例 3：当前文件为`~/project/src/css/index/test.less`，存在`~/project/.git`目录，在`vimrc`中设置`let g:OpenRequireFile_By_Map = [$HOME.'/project/src/css']

```css
/*
 * file path: ~/project/src/css/test.css
 * and the .vimrc is set: let g:OpenRequireFile_By_Map = [$HOME.'/project/src/css']
 */
@import 'g/nav'; // open: ~/project/src/css/g/nav.less
@import "g/nav'; // open Error!  " != ' Label mismatch.

// file path: ~/project/src/css/g/test.css
@import    "../nav/index.css' // open: ~/project/src/css/nav/index.css
// file path: ~/project/src/css/test.css
@import "index" // open: ~/project/src/css/index.less
```

例 4：当前文件为`~/project/src/js/index/tpl/test.tpl`，存在`~/project/.git`目录，在`vimrc`中设置`let g:OpenRequireFile_By_Map = [$HOME.'/project/src/js']

```html
<p>打开文件<%=include('./na|v.tpl')%>   // | 为光标所在位置   open: ~/project/src/js/index/tpl/nav.tpl
```

## 变量

#### `g:OpenRequireFile_By_Map`

指定项目的根目录地址，绝对地址方式需要指定项目根地址。默认值为`[]`

```vim
let g:OpenRequireFile_By_Map = [
	\ $HOME.'/Git/project/src/js',
	\ $HOME.'/Git/project/src/css',
	\ $HOME.'/Git/projectB/lib',
	\ ]
```

#### `g:OpenRequireFile_By_Repository`

通过文件或目录标记的形式指定项目根地址。默认值：`['.git', '.svn', '.hg']`

```vim
let g:OpenRequireFile_By_Repository = [
	\ '.git',
	\ '.svn',
	\  '.hg',
	\ '.HereIsMyProjectRoot'
	\ ]
```

**注意**：如果所标记目录下存在`src`文件夹，那么项目根目录会被指定为`src`目录。

## TODO

 - 支持打开 npm 安装包中的文件
 - 进一步学习 VimScript，改进插件代码

## 申明

插件目前只在 Macbook Pro 中测试通过，未在其它平台上测试，欢迎大家使用并反馈问题。

这是我写的第一插件，质量以及性能上应该都有问题，也希望 VIML 达人指点，谢谢！

License: MIT
