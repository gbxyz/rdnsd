#!/usr/bin/perl
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	'NAME'		=> 'rdnsd',
	'VERSION_FROM'	=> 'rdnsd',
	'ABSTRACT_FROM'	=> 'rdnsd',
	'AUTHOR'	=> 'Gavin Brown <gavin.brown@centralnic.com>',
	'LICENSE'	=> 'perl',
	'EXE_FILES'	=> [ 'rdnsd' ],
	'PREREQ_PM'	=> {
		'Config::Simple'	=> 0,
		'DBI'			=> 0,
		'Getopt::Long'		=> 0,
		'IO::File'		=> 0,
		'List::Util'		=> 0,
		'Net::DNS'		=> 0,
		'POSIX'			=> 0,
		'Pod::Usage'		=> 0,
		'Sys::Hostname'		=> 0,
		'Sys::Syslog'		=> 0,
		'Time::HiRes'		=> 0,
	},
);
