# diffviz - a diff visualizer for Kakoune

Note: This is very much experimental! Commands, syntax usage may change without
notice! Use at your own risk.

The diffviz plugin provides you with a few commands to visualize differences
between files or buffers.

## Installing

Assuming you're using `plug.kak`, you can just add the following line
to your kakoune config:

```kak
plug "winged/kak-diffviz"
```

## Usage

The core of the plugin is the `diff-buffers` command. Setup your editor such
that you have the files you want to compare in two buffers of the same session.
Let's say you have a version of your file in buffer A, and another version of it
in buffer B:  Then, in buffer A, run `:diff-buffers B`. Kakoune will now show
you all the changes in the left of the column, and keep them up to date!

Note that due to the way this works, we cannot show deleted lines in the current
buffer. Thus, the view is not entirely symmetrical: There's always the "main"
window, which defines the primary perspective. Deleted lines will show up in the
"other" window as dash prefixes. 

To compare your current file with the version that's currently committed in Git,
you can run `:diff-git`. It will open a new buffer and show the changes between
your version and the git version side by side.

You can stop the diff mode by running `:diff-end`. This will close the "git"
reference window and disable the diff highlighter. If you've started the diff
mode using `:diff-buffers`, the reference buffer will be kept.


## Contributions 

Contributions are very welcome! But please before sending bigger pull
requests, create an issue instead and let me know if you intend to fix
it yourself, so we can have a discussion before too much work is done.

## TODO

Here's some features that I'd like to see:

* synchronized scrolling
* performance improvements
* syntax highlighting for the reference files
* maybe highlight the whole line instead of just the gutter
