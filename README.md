# NAME

rdnsd is a remote DNS server monitoring system.

# DESCRIPTION

`rdnsd` can be used to monitor the availability and responsiveness of
remote DNS servers. Given a list of DNS servers, it will periodically
query each server and record whether a response was received, and how
quickly. This information can then be obtained by querying an SQLite
database.

# USAGE

        C<rdnsd> OPTIONS

# OPTIONS

The following command line options are supported:

- `--help`

    Display help text.

- `--config=FILE`

    Specify the configuration file. See ["CONFIGURATION FILE"](#configuration-file) for further
    details. If not specified, `/etc/rdnsd/rdnsd.conf` is used.

- `--debug`

    Enable debug mode. `rdnsd` will not daemonise and will emit debugging
    information to STDERR.

# CONFIGURATION FILE

`rdnsd` must be configured using a configuration file. The following
is an example:

        NodeID          my-node-id
        UpdateInterval  293
        PidFile         /var/run/rdnsd/rdnsd.pid
        Database        /var/run/rdnsd/rdnsd.db
        Percentile      95
        AddressFamily   4
        Protocol        udp
        Loop            3
        Timeout         1
        Recurse         false
        Question        . A IN
        Servers         ns1.example.com,ns2.example.net
        Domains         example.com

The directives are explained below.

- `NodeID ID`

    Default: `$HOSTNAME`

    This value is insterted into the \`node\_id\` column of stats database. It
    disambiguates the source of each row, allowing data from multiple
    monitoring nodes to be aggregated losslessly.

    If not set, the system's host name is used.

- `UpdateInterval TIME`

    Default: `293`

    This parameter tells `rdnsd` to automatically update the statistics
    database every `TIME` seconds. This value **MUST** be more than
    `Loop x Timeout` seconds, and **SHOULD** be at least three times that
    value.

- `PidFile /path/to/pid/file`

    Default: `/var/run/rdnsd/rdnsd.pid`

    The file where `rdnsd` will write its pid.

- `Database FILE`

    Default: `/var/run/rdnsd/rdnsd.sqlite`

    If set, `rdnsd` will create an SQLite database at the specified file
    and write statistics to it. The database will contain a single table
    named `rdnsd`, which will contain the following columns:

    - `id` - unique row ID
    - `node_id` - node ID/hostname
    - `start_time` - date+time the monitoring interval began
    - `ends_time` - date+time the monitoring interval ended
    - `host` - server name
    - `family` - IP version (4 or 6)
    - `proto` - transport protocol (UDP or TCP)
    - `count` - number of queries sent to the server
    - `success` - number of successful queries
    - `rate` - response rate as a decimal between 0 and 1 (equivalent
    to `success / rate`)
    - `min_time` - lowest observed RTT in milliseconds
    - `time` - average RTT in milliseconds
    - `time` - highest observed RTT in milliseconds
    - `percentile_time` - average RTT in milliseconds at the
    configured percentile.

- `Percentile PERCENTILE`

    Default: none

    If this option is set, `rdnsd` will calculate the response time at the
    given percentile.

- `AddressFamily (4|6)`

    Default: `4`

    Specifies whether to prefer IPv4 or IPv6 when talking to nameservers, if
    the servers are identified by name rather than address (or when loaded
    from SRV records). If not defined, the default behaviour is to prefer
    IPv4.

- `Protocol (udp|tcp)`

    Default: `udp`

    Specify the transport protocol (UDP or TCP) to use.

- `Loop SECONDS`

    Default: `3`

    This specifies the length of the main loop. If this is set to 2, then
    each server will be checked every 2 seconds. This value can be a decimal
    fraction, eg 0.25.

- `Timeout SECONDS`

    Default: `1`

    This specifies the timeout for DNS queries. A server will be considered
    down if it does not respond within this amount of time. This value
    **MUST** be less than the value of `Loop`.

- `Recurse (true|false)`

    Default: `false`

    Enable recursion (i.e. set the \`rd\` bit on the queries sent to servers).

- `Question QUESTION`

    Default: `example.com. IN A`

    Specify the DNS question. The format is "QNAME QCLASS QTYPE".

- `Servers SERVERS`

    Default: none

    Specify the servers to be checked. You can either specify a server name
    (which will be resolved to a set of IP addresses), or literal IPv4 or
    IPv6 addresses.

    This directive can't be used at the same time as the `Domains`
    directive.

- `Domains DOMAINS`

    Default: none

    Rather than specifying a list of nameservers, you can provide a list of
    domains instead. For each domain, `rdnsd` will query for `SRV` records
    for `_dns._udp` under the domain and use the targets of any `SRV`
    records returned.

    The server list will be updated when the TTL on the `SRV` records
    expires.

    This directive can't be used at the same time as the `Servers`
    directive.

- `StatsFile /path/to/stats/file`

    Default: none

    **Note:** this is a legacy option to provide backwards compatibility with
    older versions of `rdnsd`. It specifies a file to which `rdnsd` will
    write statistics.

    See ["LEGACY STATISTICS FILE FORMAT"](#legacy-statistics-file-format) for further information.

# RELOADING CONFIGURATION

`rdnsd` will reload its configuration if you send it a `SIGHUP`:

        $ kill -HUP `cat /path/to/pid/file`

# OBTAINING STATISTICS

Every `UpdateInterval` seconds, `rdnsd` will write stats to the SQLite
database specified by `Database`, and, if set, the file specified by
`StatsFile`.

Once the database has been updated, `rdnsd`'s internal data is reset,
so subsequent signals will produce fresh statistical data.

## LEGACY STATISTICS FILE FORMAT

Older versions of `rdnsd` used a flat file format for statistics, which
would be updated every `UpdateInterval` seconds, or when `rdnsd`
received the `USR1` signal. This behaviour is now deprecated in favour
of the SQLite database, but is still supported for backwards
compatibility.

The statistics file will contain one line for each server. Each line
contains the nameserver checked, the response rate as a decimal
fraction, and the average response time (in milliseconds), for example:

        ns0.example.com 1.00 25

If the `Percentile` option is set in the config file (or the
`--percentile` argument was given), an additional value will appear at
the end of the line:

        ns0.example.com 1.00 25 36

This value is the response time (in milliseconds) at the given
percentile.

# SEE ALSO

- [https://www.centralnic.com/](https://www.centralnic.com/)
- [http://www.net-dns.org/](http://www.net-dns.org/)

# COPYRIGHT

`rdnsd` is Copyright 2019 CentralNic Ltd. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 611:

    You forgot a '=back' before '=head1'
