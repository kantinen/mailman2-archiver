# Mailman2 Archiver

Here's a script to download your mailman2 archive.

To use the script, you will have to create the (`.gitignore`d) file
`mailman.conf` with the following variables:

    BASEURL="https://ourmailmandomain.org/mailman/private"
    LIST="ourmailinglist"
    USER="mymail@mydomain.org"
    PASSWORD="password123"

You should've gotten the password when you signed up for the mailing list,
otherwise, you can [ask your mailman to send your **plain-text(!!!)** password
to you](http://www.list.org/mailman-member/node16.html).

## License

MIT
