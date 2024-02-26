Finnish Trams Fix
-------------

Contents:

1 About
2 Usage and Parameters
3 Obtaining the source
4 Compiling from source
5 Credits


-------
1 About
-------

Finnish Trams includes trams used in Finland from the late 19th century
horse-driven trams to modern day articulated trams.

The trams are based on their real-life counterparts, with speed and
capacity adjusted for gameplay.


----------------------
2 Usage and Parameters
----------------------

Right-hand traffic is recommended with this NewGRF, as most trams have
doors opening to the right side.

All NewGRF a parameters are fully described in the parameter selection
menu.


----------------------
3 Obtaining the source
----------------------

The source code can be obtained from the #openttdcoop DevZone at
    http://dev.openttdcoop.org/projects/finnishtrams
or via mercurial checkout
    hg clone http://hg.openttdcoop.org/finnishtrams


-----------------------
4 Compiling from source
-----------------------

Prerequisites:
    gcc
    GNU make
    NewGRF Meta Language compiler (nmlc)
    python3
    xcftools

The source can be compiled simply by running
    make
without any arguments.

Overview of all Makefile targets:

all:
    This is the default target, if also no parameter is given to make.
    It will build the grf file.

bundle_tar
    This will tar the grf file and docs into a tar archive for
    distribution or upload to bananas.

bundle_zip
    This will zip the tar archive into one zip for distribution.

bundle_src
    Creates a source bundle.

clean:
    Deletes files this Makefile creates.

install:
    This will copy the tar archive into DESTDIR
    (default: $HOME/.openttd/newgrf).

maintainer-clean:
    As clean, but deletes all nml cache as well.

uninstall:
    This will remove any tar archives matching the name of this project
    from DESTDIR.


---------
5 Credits
---------

Coding, graphics: juzza1

Special thanks to #openttdcoop Development Zone maintainers for
repository hosting, and the original make-nml framework.
