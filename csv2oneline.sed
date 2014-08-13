# if last line, print and exit
$ { p; b; }

# copy pattern in hold, read next line
h; n;

# while line ok print
:checkline
/^[A-Z]\{4\}-[0-9]\{5\}/ {
    # clean and print previous
    x; s/\n/ /g; p;
    # if last line, print and exit
    $ { x; p; b; }
    # read next line
    n; b checkline;
}

# append, clean, print
H; n; b checkline;
