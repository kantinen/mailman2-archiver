# Mailman2 Archiver

Here's a script to download your mailman2 archive.

## Configuration

To use the script, you will have to create a configuration file containing e.g.
the following:

    BASEURL="https://ourmailmandomain.org/mailman/private"
    LIST="ourmailinglist"
    USERNAME="mymail@mydomain.org"
    PASSWORD="password123"

You should've gotten the password when you signed up for the mailing list,
otherwise, you can [ask your mailman to send your **plain-text(!!!)** password
to you](http://www.list.org/mailman-member/node16.html).

For user-friendliness, you can add the following Vim and Emacs modelines at the
top of your configuration file:

    # -*- mode: conf-mode -*-
    # vim: set ft=config

## Archiving

Assuming you have a `mailman.conf` and want to archive _everything_, you can
just do:

    $ ./archive.sh

To specify a configuration file other than `mailman.conf`, use the `-c` or
`--conf` option:

    $ ./archive.sh -c kantinen.org--bestyrelsen

To archive a particular sub-archive, specify it as the follow-up argument. For
instance:

    $ ./archive.sh 2015-March

or

    $ ./archive.sh -c kantinen.org--bestyrelsen 2015-March

## License

MIT
