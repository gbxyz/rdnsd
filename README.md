# NAME

`rdnsd` - a remote DNS server monitoring tool

# DESCRIPTION

`rdnsd` is a tool which can be used to monitor the availability and
responsiveness remote DNS servers. Given a list of DNS servers, it will
periodically query each server in turn and record whether a response was
received, and how quickly. This information can then be obtained by
sending a signal to the `rdnsd` process - a Munin plugin is provided as an
example of how this can be achieved.

# USAGE

        C<rdnsd> [OPTIONS]

# OPTIONS

- `--help`

    Display help text.

- `--config=FILE`

    Specify the configuration file. See ["CONFIGURATION FILE"](#configuration-file) for further
    details. Arguments passed on the command line will override the contents
    of this file.

- `--debug`

    Set `Debug` option.

- `--multithreaded`

    Set `Multithreaded` option.

- `--pidfile=FILE`

    Set `PidFile` option.

- `--database=FILE`

    Set `Database` option.

- `--percentile=PERCENTILE`

    Set `Percentile` option.

- `--family=(4|6)`

    Set `Family` option.

- `--proto=(udp|tcp)`

    Set `Protocol` option.

- `--loop=LOOP`

    Set `Loop` option.

- `--timeout=TIMEOUT`

    Set `Timeout` option.

- `--recurse`

    Set `Recurse` option.

- `--question=QUESTION`

    Set `Question` option.

- `--servers=SERVERS`

    Set `Servers` option.

- `--domains=DOMAINS`

    Set `Domains` option.

- `--optimistic`

    Set `Optimistic` option.

- `--update=TIME`

    Set `UpdateInterval` option.

- `--statsfile=FILE`

    Set `StatsFile` option.

# CONFIGURATION FILE

The easiest way to configure `rdnsd` is to provide a configuration file.
The format is very simple. Here is an example:

        Debug           false
        MultiThreaded   true
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
        Optimistic      false
        UpdateInterval  300

The directives are explained below. As noted above, if the equivalent
command line argument is passed, it will override the value in the
configuration file.

- `Debug (true|false)`

    Default: `false`

    Normally, `rdnsd` will daemonise once started. If the `Debug` parameter
    is `true`, `rdnsd` will stay in the foreground and spam your terminal
    with debugging information.

- `Multithreaded (true|false)`

    Default: `true`

    This parameter enables multithreaded mode. In this mode, `rdnsd` will
    probe servers in parallel inside separate threads. Otherwise, it probes
    them in serial, one after the other. Use of multithreaded mode resolves
    some issues with monitoring large numbers of servers, at the cost of
    higher CPU load.

- `PidFile /path/to/pid/file`

    Default: `/var/run/rdnsd/rdnsd.pid`

    The file where `rdnsd` will write its pid.

- `Database FILE`

    Default: `/var/run/rdnsd/rdnsd.sqlite`

    If set, `rdnsd` will create an SQLite database at the specified file
    and write statistics to it. The database will contain a single table
    named `rdnsd`, which will contain the following columns:

    - `id` - unique row ID
    - `date` - date/time the row was inserted
    - `host` - hostname
    - `family` - IP version (4 or 6)
    - `proto` - transport protocol (UDP or TCP)
    - `rate` - response rate as a decimal (0.00 - 1.00)
    - `time` - average RTT in milliseconds
    - `percentile_time` - average RTT in milliseconds at the
    configured percentile.

- `Percentile PERCENTILE`

    If this option is set, `rdnsd` will calculate the response time at the
    given percentile. See ["STATISTICS FILE FORMAT"](#statistics-file-format) for further information.

- `AddressFamily (4|6)`

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
    down if it does not respond within this amount of time.

- `Recurse (true|false)`

    Default: `false`

    Enable recursion.

- `Question QUESTION`

    Default: `example.com. IN A`

    Specify the DNS question. The format is "QNAME QCLASS QTYPE".

- `Servers SERVERS`

    Default: none

    Specify the servers to be checked. This directive can't be used at the
    same time as the "Domains" directive.

- `Domains DOMAINS`

    Default: none

    Rather than specifying a list of nameservers, you can provide a list of
    domains instead. For each domain, `rdnsd` will query for SRV records for
    `_dns._udp` under the domain and use the targets of any SRV records
    returned.

    The SRV record is checked once at start-up, so if the list of hosts
    changes, you will need to restart `rdnsd`.

- `Optimistic (true|false)`

    Default: `false`

    This parameter controls what happens when `rdnsd` outputs statistics but
    finds a server in its list that it has not yet had time to send a
    query to. If its value is true, then the server will be reported as up;
    if false, it will be reported as down.

- `UpdateInterval TIME`

    Default: `293`

    This parameter tells `rdnsd` to automatically update the statistics file
    every `TIME` seconds.

- `StatsFile /path/to/stats/file`

    Default: none

    **Note:** this is a legacy option to provide backwards compatibility.

    Th specifies the file where `rdnsd` will write statistics to when
    signalled. See ["OBTAINING STATISTICS"](#obtaining-statistics) for further information.

# RELOADING CONFIGURATION

`rdnsd` will reload its configuration if you send it a `SIGHUP`:

        $ kill -HUP `cat /path/to/pid/file`

Arguments originally specified on the command line will always override
new options added to the configuration file.

# OBTAINING STATISTICS

Every `UpdateInterval` seconds, `rdnsd` will write stats to the SQLite
database specified by `Database`, and, if set, the file specified by
`StatsFile`.

The recommended way to obtain statistics is to query the SQLite database
specified by the `Database` directive.

If `UpdateInterval` is unset, automatic updates will not occur, so to
get statistics out of `rdnsd`, you must sending it a `USR1` signal:

        $ kill -USR1 `cat /path/to/pid/file`

**NOTE:** if multithreaded mode is disabled, and you have `N` servers
and a `Loop` value of `M`, you must be careful not to send the USR1
signal to `rdnsd` more often than every `N x M` seconds, otherwise
`rdnsd` will not have enough time to test every server. You probably
want to send the signal about every `3 x N x M` seconds if you want
reliable statistics when not running in multithreaded mode.

If `rdnsd` _is_ running in multithreaded mode, then you can send the
`USR1` signal much more often (once every `Loop x Timeout` seconds).

## (LEGACY) STATISTICS FILE FORMAT

The (legacy\* statistics file will contain one line for each server that
is being checked. Each line contains the nameserver checked, the response
rate as a decimal fraction, and the average response time (in milliseconds),
for example:

        ns0.example.com 1.00 25

If the `Percentile` option is set in the config file (or the
`--percentile` argument was given), an additional value will appear at
the end of the line:

        ns0.example.com 1.00 25 36

This value is the response time (in milliseconds) at the given
percentile.

Once the file has been written, `rdnsd`'s internal data is reset, so
subsequent signals will produce fresh statistical data.

Note that `rdnsd` will not _immediately_ update the file upon receiving
the `USR1` signal. You may need to wait up to `Loop` seconds for the
current loop iteration to complete before the stats file is updated.

# SEE ALSO

- [https://www.centralnic.com/](https://www.centralnic.com/)
- [http://www.net-dns.org/](http://www.net-dns.org/)

# COPYRIGHT

`rdnsd` is Copyright 2013 CentralNic Ltd. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
