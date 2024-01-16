#!/usr/bin/perl
#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use strict;
use warnings;
use FindBin;

my $plugins = [];

sub check_directory {
    my ($directory) = @_;

    opendir(my $dh, $directory) || return ;
    while (my $filename = readdir $dh) {
        check_directory($directory . '/' . $filename) if ($filename !~ /^\./ && -d $directory . '/' . $filename);
        if ($filename eq 'plugin.pm') {
            push @$plugins, $directory . '/' . $filename;
        }
    }
    closedir $dh;
}

sub check_custommode {
    my (%options) = @_;

    my $cmodes = `$options{bin} --plugin=$options{plugin} --list-custommode`;
    if ($cmodes !~ /Custom Modes Available:\n(.*)/ms) {
        print "    mode: $options{mode}, result=$cmodes";
        return ;
    }
        
    foreach my $cmode (split /\n/, $1) {
        $cmode =~ s/\s+//g;
        my $result = `$options{bin} --plugin=$options{plugin} --custommode=$cmode --mode=$options{mode}`;
        print "    mode: $options{mode}, custommode: $cmode, result=$result";
    }
}

my $plugin = "$FindBin::Bin/../centreon_plugins.pl";
check_directory("$FindBin::Bin/..");

foreach my $plugin_path (@$plugins) {
    $plugin_path =~ s{$FindBin::Bin/../}{};
    print "plugin: $plugin_path\n";
    my $modes = `$plugin --plugin=$plugin_path --list-mode`;
    if ($modes =~ /Modes Available:\n(.*)/ms) {
        foreach my $mode (split /\n/, $1) {
            $mode =~ s/\s+//g;
            my $result = `$plugin --plugin=$plugin_path --mode=$mode`;
            if ($result =~ /Need to specify '--custommode'/i) {
                check_custommode(bin => $plugin, plugin => $plugin_path, mode => $mode);
            } else {
                print "    mode: $mode, result=$result";
            }
        }
    } else {
        print "error: $modes\n";
    }

    print "\n";
}

exit(0);
