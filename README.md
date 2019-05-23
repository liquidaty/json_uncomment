## json_uncomment
Cross-platform utility to strip comments and optionally minify JSON

## why
There are many JSON uncomment utilities, but none I tried worked for my purposes:
* Many had fundamental problems such as not working for all JSON. For example, I don't believe it's possible to properly strip comments using regular expressions, and yet many libraries try to do exactly that (such as https://github.com/vaidik/commentjson/issues/16)
* Every utility I tried would change the size of the output, which is a problem for me because where possible I prefer to use JSON schema validation, and with these utilies that change the input size, location tracking was useless because locations in the stripped JSON could not be translated into locations in the original input

## how
json_uncomment uses a very simple approach to solve the above issues. First, it uses a proper lexer to parse the JSON. Second, it provides an option to retain input size (and therefore locations other than for comments). Features include:
* very small code base of ~50 lines of lex instructions (which should be easily portable to any language), plus ~12 lines of wrapper code
* can be compiled / run on any platform and easily invoked by virtually any language that can call a shell and pipe stdin/stdout
* by default, the output has the same number of characters as the input (comments are replaced with whitespace), so that any subsequent schema validation location tracking will properly corresponds to the original input
* in optional "compact" mode, extraneous whitespace is not emitted

## building
To build, run:
   make [RELEASE=1] json_uncomment

To cross-compile using mingw64, run:
   make [RELEASE=1] WIN=1

The optional RELEASE=1 flag will build with full compiler optimizations
