# Tsuquyomi

Tsuquyomi is a Vim plugin for TypeScript.

## Features

Tsuquyomi works as a client for **TSServer**(which is an editor service bundled into TypeScript).
So, installing Tsuquyomi, your vim gets the following features provided by TSServer:

+ Completion (omni-completion)
+ Navigate to the location where a symbol is defined.
+ Show location(s) where a symbol is referenced.
+ Display a list of syntax and seamantics errors to Vim quickfix window.
+ and so on,,,

## How to install
Tsuquyomi requires the following:

+ [Vim](http://www.vim.org/) (v7.4.0 or later)
+ [Shougo/vimproc.vim](https://github.com/Shougo/vimproc.vim)
+ [Node.js](https://nodejs.org/) & [TypeScript](https://github.com/Microsoft/TypeScript) (**v1.5.0 or later**)

If you use [NeoBundle](https://github.com/Shougo/neobundle.vim) for Vim plugin management, append the following to your `.vimrc`:

```vim
NeoBundle 'Shougo/vimproc'
NeoBundle 'Quramy/tsuquyomi'
```

And exec `:NeoBundleInstall`, make vimproc runtime.

```bash
cd ~/.vim/bundle/vimproc
make
```

(About vimproc installation, please see [the original install guide](https://github.com/Shougo/vimproc.vim#install).)

### Remarks
**TypeScript v1.5.0 is not released. If you install TypeScript with `npm -g install typescript`, the installed version is not v1.5.0 but v1.4.x.**

**So, until v1.5.0 is rerelased, setup with the following procedures (select A. or B.):**

#### A. Global install

```bash
npm -g install git://github.com/Microsoft/TypeScript.git
```

#### B. Local install

```bash
cd ~/.vim/bundle/tsuquyomi
npm install
```

For using `~/.vim/bundle/tsuquyomi/node_modules/typescript/bin/tsserver.js` installed above, append the following to your `.vimrc`:

```vim
let g:tsuquyomi_use_dev_node_module = 1
```


## Usage

### Completion
Tsuquyomi supports Omni-Completion.

By the default, type `<C-x> <C-o>` in insert mode, Tsuquyomi shows completions.

### Nav to definition
Type `<C-]>` in normal mode or visual mode, Tsuquyomi navigates to the location where the symbol under the cursor is defined.

Alternatively, call the Ex comand `:TququyomiDefinition`.

### Show references
Type `<C-^>` in normal mode or visual mode, Tsuquyomi shows a list of location where the symbol under the cursor is referenced.

Alternatively, call the Ex comand `:TsuquyomiReferences`.

### Show quickfix
When a buffer is saved, Tsuquyomi checks syntax and semantics.
And if it contains errors, Tsuquyomi show them to Vim quickfix window.

### Rename symbols

Using the command `:TsuquyomiRenameSymbol`, you can rename the identifiler under the cursor to a new name.

This feature does not have the default key mapping.
If you need, configure your `.vimrc` . For example: 

```vim
autocmd FileType typescript nmap <buffer> <Leader>e <Plug>(TsuquyomiRenameSymbol)
```

### Show tooltip(balloon)
Tsuquyomi can display tooltip window about symbol under the mouse cursor.
If you want to use this feature, configure `.vimrc` as follows:

```vim
set ballooneval
autocmd FileType typescript setlocal ballonexpr=tsuquyomi#ballonexpr()
```


If you want more details, please see [doc](doc/tsuquyomi.txt).

## Future works

+ outline 
+ syntax highright
+ etc ...

## License
MIT
