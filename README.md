# Tsuquyomi

Tsuquyomi is a Vim plugin for TypeScript developers.

## Features

+ Completion (omni-completion)
+ Navigate to the location where a symbol is defined.
+ Show location(s) where a symbol is referenced.
+ Display a list of syntax and seamantics errors to Vim quickfix window.

## Requirements

+ [Vim](http://www.vim.org/) (v7.4 or later)
+ [Shougo/vimproc.vim](https://github.com/Shougo/vimproc.vim)
+ [Node.js](https://nodejs.org/)
+ [TypeScript](https://github.com/Microsoft/TypeScript) (**1.5.0 or later**)

### Remarks
**TypeScript v1.5.0 is not released. If you install TypeScript with `npm -g install typescript`, the installed version is not v1.5.0 but v1.4.x.**

**So, until v1.5.0 will be rerelased, please setup with the following procedure:**

1. Get latest version TypeScript from github repo.

```bash
cd ~/someDirectory
git clone https://github.com/Microsoft/TypeScript
```

1. Edit your .vimrc and append the following: 

```vim
let g:tsuquyomi_use_dev_node_module = 2
let g:tsuquyomi_tsserver_path = "~/someDirectory/TypeScript/bin/tsserver.js"
```

## Usage

### Completion
Tsuquyomi supports Omni-Completion.

By the default, type <C-x> <C-o> in insert mode, Tsuquyomi shows completions.

### Nav to definition
Type <C-]> in normal mode or visual mode, Tsuquyomi navigates to the location where the symbol on the cursor is defined.

Alternatively, call the Ex comand `:TququyomiDefinition`.

### Show references
Type <C-[> in normal mode or visual mode, Tsuquyomi shows a list of location where the symbol on the cursor is referenced.

Alternatively, call the Ex comand `:TsuquyomiReferences`.

### Show quickfix
When a buffer is saved, Tsuquyomi checks syntax and semantics.
And if it contains errors, Tsuquyomi show them as a quickfix window.


## Future works

+ rename
+ formatting
+ syntax highright
+ etc ...

## License
MIT
