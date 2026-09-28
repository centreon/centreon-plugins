#!/usr/bin/perl
#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
# Run PAR::Packer's pp with arguments read from a file (one token per line,
# whitespace-separated tokens allowed), bypassing the Windows cmd ~8191-char
# command-line length limit that the long -M/--link list otherwise exceeds.
#
# Usage: perl run-pp.pl <args-file>
use strict;
use warnings;

my $args_file = shift @ARGV or die "usage: run-pp.pl <args-file>\n";

open(my $fh, '<', $args_file) or die "cannot open $args_file: $!\n";
my @args;
while (my $line = <$fh>) {
    $line =~ s/\r?\n\z//;
    $line =~ s/^\s+//;
    $line =~ s/\s+\z//;
    next if $line eq '';
    # None of our arguments (module names, C:\... paths, options) contain
    # spaces, so splitting each line on whitespace yields the argv tokens.
    push @args, split(/\s+/, $line);
}
close($fh);

my $pp = 'C:/Strawberry/perl/site/bin/pp';
my $rc = system($^X, $pp, @args);
if ($rc == -1) {
    die "failed to execute pp: $!\n";
}
exit($rc >> 8);
