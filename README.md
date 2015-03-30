# Tsuquyomi

Tsuquyomi is a Vim plugin for TypeScript developers.

## Features

Tsuquyomi works as a client for **TSServer**(which is an editor service bundled TypeScript).
So, installing Tsuquyomi your vim gets the following features provided by TSServer:

+ Completion (omni-completion)
+ Navigate to the location where a symbol is defined.
+ Show location(s) where a symbol is referenced.
+ Display a list of syntax and seamantics errors to Vim quickfix window.

## How to install
Tsuquyomi requires the followings:

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
cd ~/${VIM_PLUGIN_DIR}/bundle/vimproc
make
```

(About vimproc installation, please see [the original install guide](https://github.com/Shougo/vimproc.vim#install).)

### Remarks
**TypeScript v1.5.0 is not released. If you install TypeScript with `npm -g install typescript`, the installed version is not v1.5.0 but v1.4.x.**

**So, until v1.5.0 is rerelased, setup with the following procedure:**

```bash
npm -g install git://github.com/Microsoft/TypeScript.git
```

## Usage

### Completion
Tsuquyomi supports Omni-Completion.

By the default, type `<C-x> <C-o>` in insert mode, Tsuquyomi shows completions.

### Nav to definition
Type `<C-]>` in normal mode or visual mode, Tsuquyomi navigates to the location where the symbol on the cursor is defined.

Alternatively, call the Ex comand `:TququyomiDefinition`.

### Show references
Type `<C-^>` in normal mode or visual mode, Tsuquyomi shows a list of location where the symbol on the cursor is referenced.

Alternatively, call the Ex comand `:TsuquyomiReferences`.

### Show quickfix
When a buffer is saved, Tsuquyomi checks syntax and semantics.
And if it contains errors, Tsuquyomi show them to Vim quickfix window.

If you want more details, please see [doc](blob/master/doc/tsuquyomi.txt).

## Future works

+ rename
+ formatting
+ syntax highright
+ etc ...

## License
MIT
