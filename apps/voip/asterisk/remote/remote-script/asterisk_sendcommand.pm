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
# Revision 1.0  2015/01/16 11:15     David Sabatie <dsabatie@centreon.com>
# Release based on already existing munin script
#
# Parameters mandatory:
#
# 	username
# 	secret
#
#%# family=asterisk
#%# capabilities=autoconf

use strict;
use File::Basename;

my $ret = undef;
if (! eval "require Net::Telnet;")
{
    $ret = "Net::Telnet not found";
}

my $DIRNAME=dirname($0);
my $conffile=$DIRNAME."/asterisk_centreon.conf";

my $command;
if ( (defined($ARGV[0])) && ($ARGV[0] ne '') )
{
    $command = $ARGV[0];
}
else
{
    print 'No command to send';
    exit;
}

my $host = exists $ENV{'host'} ? $ENV{'host'} : "127.0.0.1";
my $port = exists $ENV{'port'} ? $ENV{'port'} : "5038";

#[asterisk_*]
#env.username xivo_centreon_user
#env.secret secretpass

my ($username, $secret);

open FILE, $conffile or die $!;
while (my $confline = <FILE>)
{
	     ($username, $secret) = split(' ', $confline);
}
close(FILE);

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

$line = $pop->getline;
$line = $pop->getline;
if ($line !~ /^Message: Authentication accepted/) {
    print 'Unable to connect to AMI: ' . $line;
    exit;
}

## Request status of messages.
$pop->print("Action: command");
$pop->print("Command: ".$command);
$pop->print("");
$line = $pop->getline;
$line = $pop->getline;
$line = $pop->getline;
while (($line = $pop->getline) and ($line !~ /END COMMAND/o))
{
    print $line;
}
$pop->print("Action: logoff");
$pop->print("");
$pop->close();

# vim:syntax=perl
