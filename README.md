historian
=========

Command-line utility for managing shell history in a SQLite database.

`~/.bash_history` is deduped and imported into a database.

### Requirements

* SQLite
* a home directory

### Installation

Download and 1) add the directory to your `$PATH`

    export PATH="$PATH:/Users/jerry/historian"

or 2) add `hist` as an alias.

    alias hist="/Users/jerry/historian/hist"

### Getting Started

Import your `~/.bash_history`

    $ hist import

### Usage

Show config:

    version:      0.0.1
    bash_history: /Users/jerry/.bash_history
    db:           /Users/jerry/.historian.db
    sqlite3:      /opt/local/bin/sqlite3

Search:

    $ hist search monsters
    690
        echo a zombie with no conscience >> ~/monsters
    689
        echo ghoul >> ~/monsters
    688
        echo goblin >> ~/monsters
    687
        echo lochness >> ~/monsters

Search (shorthand):

    $ hist /monsters
    690
        echo a zombie with no conscience >> ~/monsters
    689
        echo ghoul >> ~/monsters
    688
        echo goblin >> ~/monsters
    687
        echo lochness >> ~/monsters

View log:

    $ hist log
    1020
        rm -f README.md
    1019
        emacs README.md
    1018
        rm -rf .git

### Pitfalls

Live like your db file could be corrupted at any time.

Be wary of running specially crafted `hist` commands or against
`~/.bash_history` files.

### Cool Things in the Future

* `export` to append to `~/.bash_history`
* `scrub` items from history
* set or autodetect configs
* other shells than bash
* timestamp support
