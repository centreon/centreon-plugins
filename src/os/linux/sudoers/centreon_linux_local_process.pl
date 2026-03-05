#!/usr/bin/perl
#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

die "Invalid call\n" unless @ARGV;

my $dh;
foreach my $pid (@ARGV) {
    die "Invlid PID '$pid'\n" unless $pid =~ /^\d+$/;

    my $dir = "/proc/$pid/fd";

    my $count = 0;
    if (opendir $dh, $dir) {
        # do not count . and .. directories
        $count = grep { $_ !~ /^\./ } readdir($dh);
        closedir($dh);
    }

    print "$pid $count\n";
}
