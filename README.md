<h1>rockwriter</h1>
Tired of writing rockspecs by yourself? Here's a solution.<br>

## Why this?

Because writing rockspecs is tedious. Not only that, but when you want to update your module, you have to rename the file, open it, change the version number, change the tag if you're doing versioned CVS... it's awful, and `luarocks write_rockspec` does not help. This makes all of that easy.

## Can I use it?

It supports all features specified in the [Rockspec format page](https://github.com/luarocks/luarocks/wiki/Rockspec-format) except for patches, the `external_dependencies` table and some complex forms of the `builtin` build back-end. It's probable that you use none of these, so go ahead! (Though, if you reeeeally want them, bug me on here and I'll get on it)

## How it works

It uses [sirocco](https://github.com/giann/sirocco) to present the user prompts and confirm dialogs, making it extremely easy to write a rockspec. After all information is collected, it's just formatted and written into the actual rockspec. It also uses [filekit](https://github.com/daelvn/filekit) for file operations.

## Usage

Basically, `rockwriter <filename>` for a new rockspec, `rockwriter -u` in a directory with a rockspec to update it (you can also pass it as an argument), but here's the full usage:

```
Usage: rockwriter [-u] [--rockspec-format] [--issue-url]
       [--maintainer] [--labels] [--supported-platforms]
       [--build-deps] [--md5] [--file] [--dir] [--tag] [--branch]
       [--module] [-h] [<path>]

A tool to help you create rockspecs easily!

Arguments:
   path                  Path to the rockspec

Options:
   -u, --update          Will just update the version
   --rockspec-format     Explicitly asks for rockspec format
   --issue-url           Explicitly asks for issue URL
   --maintainer          Explicitly asks for maintainer info
   --labels              Explicitly asks for labels
   --supported-platforms Explicitly asks for supported platforms
   --build-deps          Explicitly asks for build dependencies
   --md5                 Explicitly asks for a MD5 sum for the source archive.
   --file                Explicitly asks for a name for the archive
   --dir                 Explicitly asks for a dir name for the archive to be extracted
   --tag                 Explicitly asks for a CVS tag
   --branch              Explicitly asks for a CVS branch
   --module              Explicitly asks for a CVS module
   -h, --help            Show this help message and exit.

Homepage - https://github.com/daelvn/rockwriter
```

## Maintainer

Dael \<daelvn@gmail.com\>

## License

Released to the public domain! Do what you want with it!
