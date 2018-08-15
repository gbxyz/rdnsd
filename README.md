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

    Enable debug mode.

- `--loop=LOOP`

    Set loop duration.

- `--pidfile=FILE`

    Specify pid file.

- `--family=(4|6)`

    Specify IP version.

- `--proto=QUESTION`

    Specify protocol.

- `--question=QUESTION`

    Specify question.

- `--timeout=TIMEOUT`

    Specify timeout.

- `--recurse`

    Enable recursion.

- `--servers=SERVERS`

    Specify servers to check.

- `--statsfile=FILE`

    Specify stats file.

- `--percentile=PERCENTILE`

    Specify a percentile to use when generating statistics.

- `--domains=DOMAINS`

    Specify domain names to query for a list of servers.

- `--optimistic`

    Enable Optimistic mode.

- `--update=TIME`

    Specify automatic stats update interval.

# CONFIGURATION FILE

The easiest way to configure `rdnsd` is to provide a configuration file.
The format is very simple. Here is an example:

        Debug           false
        PidFile         /var/run/rdnsd.pid
        StatsFile       /var/run/rdnsd.log
        Percentile      95
        AddressFamily   4
        Protocol        udp
        Loop            3
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

    Default: false

    Normally, `rdnsd` will daemonise once started. If the `Debug` parameter
    is `true`, `rdnsd` will stay in the foreground and spam your terminal
    with debugging information.

- `PidFile /path/to/pid/file`

    Default: var/run/rdnsd.pid

    The file where `rdnsd` will write its pid.

- `StatsFile /path/to/stats/file`

    Default: /var/run/rdnsd.log

    The file where `rdnsd` will write statistics to when signalled. See
    ["OBTAINING STATISTICS"](#obtaining-statistics) for further information.

- `Percentile PERCENTILE`

    If this option is set, `rdnsd` will calculate the response time at the
    given percentile. See ["STATISTICS FILE FORMAT"](#statistics-file-format) for further information.

- `AddressFamily (4|6)`

    Specifies whether to prefer IPv4 or IPv6 when talking to nameservers, if
    the servers are identified by name rather than address (or when loaded
    from SRC records). If not defined, the default behaviour is to prefer
    IPv6.

- `Protocol (udp|tcp)`

    Default: udp

    Specify the transport protocol to use.

- `Loop SECONDS`

    Default: 2

    This specifies the length of the main loop. If this is set to 2, then
    each server will be checked every 2 seconds. This value can be a decimal
    fraction, eg 0.25.

- `Recurse (true|false)`

    Default: false

    Enable recursion.

- `Question QUESTION`

    Default: example.com. IN A

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

    Default: false

    This parameter controls what happens when `rdnsd` outputs statistics but
    finds a server in its list that it has not yet had time to send a
    query to. If its value is true, then the server will be reported as up;
    if false, it will be reported as down.

- `UpdateInterval TIME`

    Default: none

    This paramter tells `rdnsd` to update the statistics file every `TIME`
    seconds. If set, `rdnds` will ignore the `USR1` signal (see below).

# OBTAINING STATISTICS

If `UpdateInterval` is not set, you can get statistics out of `rdnsd`
by sending it the `USR1` signal:

        $ kill -USR1 `cat /path/to/pid/file`

This will cause `rdnsd` to dump its current data to the statistics
file.

**NOTE:** if you have `N` servers and a `Loop` value of `M`, you must
be careful not to send the USR1 signal to `rdnsd` more often than every
`N x M` seconds, otherwise `rdnsd` will not have enough time to test
every server. You probably want to send the signal about every `3 x N x M`
seconds if you want reliable statistics.

Note that `rdnsd` will not immediately update the file upon receiving
the `USR1` signal: you may need to wait for the current loop iteration
to complete before the stats file is updated.

# RELOADING CONFIGURATION

`rdnsd` will reload its configuration if you send it a `SIGHUP`:

        $ kill -HUP `cat /path/to/pid/file`

## STATISTICS FILE FORMAT

The statistics file will contain one line for each server that is being
checked. Each line contains the nameserver checked, the response rate as
a decimal fraction, and the average response time (in milliseconds), for
example:

        ns0.example.com 1.00 25

If the `Percentile` option is set in the config file (or the
`--percentile` argument was given), an additional value will appear at
the end of the line:

        ns0.example.com 1.00 25 36

This value is the response time (in milliseconds) at the given
percentile.

Once the file has been written, `rdnsd`'s internal data is reset, so
subsequent signals will produce fresh statistical data.

# SEE ALSO

- [https://www.centralnic.com/](https://www.centralnic.com/)
- [http://www.net-dns.org/](http://www.net-dns.org/)

# COPYRIGHT

`rdnsd` is Copyright 2013 CentralNic Ltd. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
