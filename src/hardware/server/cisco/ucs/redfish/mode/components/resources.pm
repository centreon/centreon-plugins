# Copyright 2024 Centreon (http://www.centreon.com/)
# Licensed under the Apache License, Version 2.0

package hardware::server::cisco::ucs::redfish::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $VERSION = '1.0';
our @ISA     = ('Exporter');
our @EXPORT  = qw($thresholds_redfish);

# Redfish standard Status object:
#   { Health => 'OK|Warning|Critical', State => 'Enabled|Disabled|Absent|...' }
our $thresholds_redfish = {
    health => [
        ['^OK$',       'OK'],
        ['^Warning$',  'WARNING'],
        ['^Critical$', 'CRITICAL'],
        ['^.*$',       'UNKNOWN'],
    ],
    state => [
        ['^Enabled$',            'OK'],
        ['^Disabled$',           'WARNING'],
        ['^StandbyOffline$',     'OK'],
        ['^StandbySpare$',       'OK'],
        ['^InTest$',             'OK'],
        ['^Starting$',           'OK'],
        ['^Absent$',             'OK'],      # empty slot — not a problem by default
        ['^Deferring$',          'WARNING'],
        ['^Quiesced$',           'WARNING'],
        ['^Updating$',           'WARNING'],
        ['^UnavailableOffline$', 'CRITICAL'],
        ['^.*$',                 'UNKNOWN'],
    ],
};

1;
