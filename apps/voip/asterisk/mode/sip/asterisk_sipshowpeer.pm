#!/usr/bin/perl -w
#
# Copyright (C) 2005 Rodolphe Quiedeville <rodolphe@quiedeville.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2 dated June,
# 1991.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# If you improve this script please send your version to my email address
# with the copyright notice upgrade with your name.
#
#
# $Log$
# Revision 1.1  2005/10/22 21:04:01  rodo
# Created by Rodolphe Quiedeville
#
# Revision 1.2  2010/11/04 10:11     Guillaume Bour <gbour@proformatique.com>
#   Allow channels monitoring per device (IAX/SIP/... account or trunk).
#   To monitor a particular device, link asterisk_sipshowpeer_tech_identifier to this file, where:
#     - tech is one of SIP, IAX, DAHDI, ...
#     - identifier is account name (102, foo, ...)
#
#   i.e:
#     ls -s /path/to/asterisk_sipshowpeer /etc/munin/plugins/asterisk_sipshowpeer_trunk1
#   will monitor SIP/trunk1 device
#
#
# Parameters mandatory:
#
# 	username
# 	secret
#
#%# family=asterisk
#%# capabilities=autoconf

use strict;

my $ret = undef;
if (! eval "require Net::Telnet;")
{
    $ret = "Net::Telnet not found";
}

my $DEVICE=`basename $0`;
if ($DEVICE =~ /^asterisk_sipshowpeer_(.*)$/)
{ $DEVICE = "$1"; }
elsif (defined($ARGV[0]))
{ ($DEVICE) = @ARGV; }
else
{ $DEVICE = ''; }

my $command = 'sip show peers';

my $host = exists $ENV{'host'} ? $ENV{'host'} : "10.50.1.65";
my $port = exists $ENV{'port'} ? $ENV{'port'} : "5038";

#[asterisk_*]
#env.username xivo_munin_user
#env.secret jeSwupAd0

#my $username = $ENV{'username'};
my $username = 'xivo_munin_user';
#my $secret   = $ENV{'secret'};
my $secret   = 'jeSwupAd0';

my $pop = new Net::Telnet (Telnetmode => 0);
$pop->open(Host => $host,
	   Port => $port);

## Read connection message.
my $line = $pop->getline;
die $line unless $line =~ /^Asterisk/;

## Send user name.
$pop->print("Action: login");
$pop->print("Username: $username");
$pop->print("Secret: $secret");
$pop->print("Events: off");
$pop->print("");

#Response: Success
#Message: Authentication accepted

## Request status of messages.
$pop->print("Action: command");
$pop->print("Command: ".$command);
$pop->print("");
my @result = ('Nothing Monitored');
my $nb = 0;
while (($line = $pop->getline) and ($line !~ /END COMMAND/o))
{
#    print $line;
    if ($DEVICE eq '')
    {
        $result[$nb] = $line if $line !~ /^Name|Unmonitored/;
    }
    else
    {
        $result[$nb] = $line if $line =~ /^$DEVICE/;
    }
    $nb++;
}
$pop->print("Action: logoff");
$pop->print("");
while (($line = $pop->getline) and ($line !~ /END COMMAND/o))
{}
$pop->close();

my $peername;
my $status;
my $splitresult;

foreach (@result)
{
    if ((defined($_)) && ($_ =~ /^.*\/.* /))
    {
        chomp($_);
        $peername = $status = $_;
        $peername =~ /^(\w*)\/\w* .* (OK|Unreachable) (\(.*\))/;
	$splitresult = $1.": ".$2;
        if (defined($3))
        {
            $splitresult = $splitresult." ".$3;
        }
        print $splitresult."\n";
    }
}

# vim:syntax=perl
