#! /usr/bin/perl -w
###################################################################
# Oreon is developped with GPL Licence 2.0 
#
# GPL License: http://www.gnu.org/licenses/gpl.txt
#
# Developped by : Sugumaran Mathavarajan 
#
###################################################################
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
#    For information : contact@merethis.com
####################################################################
#
# Script init
#
use strict;
use lib "/usr/local/nagios/libexec/";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_h $opt_p $opt_H);
$PROGNAME = $0;
Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "p=s" => \$opt_p, "port=s"   => \$opt_p,
     "H=s" => \$opt_H, "hostname=s"   => \$opt_H);
if ($opt_h ) {
	print "$PROGNAME : Usage : ./check_https.pl -H [hostname/IP address -p port]\n";
	exit $ERRORS{'OK'}
}
if (!$opt_H) {
	print "$PROGNAME : Usage : ./check_https.pl -H [hostname/IP address]-p port\n";
	exit $ERRORS{'OK'}
}
if (!$opt_p) {
	$opt_p = 443;
}
my $status = "CRITICAL";
my $msg = "ERROR : couldn't connect to host.";
my $output =`/usr/bin/wget  -S  --output-document=/tmp/tmp_html https://$opt_H:$opt_p --no-check-certificate 2>&1`;
my @cmd = split /\n/, $output;
my $execute_command = `rm -f /tmp/tmp_html`;
foreach(@cmd) {
	if ($_ =~ /[\s]+HTTP\/[0-9]+\.[0-9]+[\s]+[0-9]+[\s]+OK/) {
		$msg = $_." - Request done successfully.";
		$status = "OK";
	}
} 
printf $msg."\n";
exit $ERRORS{$status};
