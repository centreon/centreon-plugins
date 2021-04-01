#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package network::adva::fsp150::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $map_admin_state;
our $map_oper_state;
our $bits_secondary_state;
our $map_card_type;
our $oids;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    $map_admin_state $map_oper_state $bits_secondary_state $map_card_type
    $oids get_secondary_states
);

$oids = {
    neName           => '.1.3.6.1.4.1.2544.1.12.3.1.1.1.2',
    shelfEntityIndex => '.1.3.6.1.4.1.2544.1.12.3.1.2.1.2',
    entPhysicalName  => '.1.3.6.1.2.1.47.1.1.1.1.7'
};

$map_admin_state = {
    1 => 'in-service', 2 => 'management',
    3 => 'maintenance', 4 => 'disabled',
    5 => 'unassigned', 6 => 'monitored'
};
$map_oper_state = {
    1 => 'normal', 2 => 'outage'
};
$bits_secondary_state = {
    0 => 'not-applicable', 1 => 'active',
    2 => 'automaticinservice', 3 => 'facilityfailure',
    4 => 'fault', 5 => 'loopback', 6 => 'maintenance',
    7 => 'mismatchedeqpt', 8 => 'standbyhot',
    9 => 'supportingentityoutage', 10 => 'unassigned',
    11 => 'unequipped', 12 => 'disabled',
    13 => 'forcedoffline', 14 => 'initializing',
    15 => 'prtcl', 16 => 'blckd', 17 => 'mon-tx',
    18 => 'mir-rx', 19 => 'cema', 20 => 'lkdo',
    21 => 'nomber'
};
$map_card_type = {
    1 => 'none', 2 => 'psu', 3 => 'fan', 4 => 'nemi',
    5 => 'scu', 6 => 'eth-10-100-1000-ntu', 7 => 'eth-cpmr',
    8 => 'eth-ge-101', 9 => 'eth-ge-206', 10 => 'eth-ge-201',
    11 => 'eth-ge-201se', 12 => 'eth-10-100-1000-nte',
    13 => 'scu-t', 14 => 'eth-ge-206f', 15 => 'eth-xg-1x',
    16 => 'swf-140g', 17 => 'stu', 18 => 'eth-ge-10s',
    19 => 'ami', 20 => 'sti', 21 => 'eth-ge-112',
    22 => 'eth-ge-114', 23 => 'eth-ge-206v',
    24 => 'eth-ge-4e-cc', 25 => 'eth-ge-4s-cc',
    26 => 'eth-xg-210', 27 => 'eth-xg-1x-cc',
    28 => 'eth-xg-1s-cc', 29 => 'stm1-4-et',
    30 => 'pwe3-ocnstm', 31 => 'pwe3-e1t1', 32 => 'eth-xg-1x-h',
    33 => 'eth-ge-10s-h', 34 => 'eth-t1804', 35 => 'eth-t3204',
    36 => 'eth-ge-syncprobe', 37 => 'eth-ge-8s-cc',
    38 => 'eth-ge-114h', 39 => 'eth-ge-114ph',
    40 => 'eth-fe-36e', 41 => 'eth-ge-114sh',
    42 => 'eth-ge-114s', 43 => 'sti-h', 44 => 'stu-h',
    45 => 'eth-ge-8e-cc', 46 => 'eth-sh1pcs', 47 => 'eth-osa5411',
    48 => 'ethGe112Pro', 49 => 'ethGe112ProM',
    50 => 'ethGe114Pro', 51 => 'ethGe114ProC',
    52 => 'ethGe114ProSH', 53 => 'ethGe114ProCSH',
    54 => 'ethGe114ProHE', 55 => 'ethGe112ProH',
    56 => 'eth-xg-210c', 57 => 'eth-ge-8sc-cc',
    58 => 'eth-osa5420', 59 => 'eth-osa5421',
    60 => 'bits-x16', 61 => 'eth-ge-114g',
    62 => 'ethGe114ProVmH', 63 => 'ethGe114ProVmCH',
    64 => 'ethGe114ProVmCSH', 65 => 'serverCard',
    66 => 'eth-ptpv2-osa', 67 => 'gnss-osa',
    68 => 'thc-osa', 69 => 'sgc-osa', 70 => 'pps-x16',
    71 => 'clk-x16', 72 => 'todAndPps-x16', 73 => 'eth-ge-101pro',
    74 => 'ethgo102proS',75 => 'ethgo102proSP',
    76 => 'ethcx101pro30A', 77 => 'ethcx102pro30A',
    78 => 'osa-ge-4s', 79 => 'eth-xg-116pro',
    80 => 'eth-xg-120pro', 81 => 'ethGe112ProVm',
    82 => 'eth-osa5401', 83 => 'eth-osa5405',
    84 => 'eth-csm', 85 => 'aux-osa', 86 => 'bits-x16-enhanced',
    87 => 'osa-ge-4s-protected', 88 => 'eth-ge-102pro-h',
    89 => 'eth-ge-102pro-efmh', 90 => 'eth-xg-116pro-h',
    91 => 'ethgo102proSM', 92 => 'eth-xg-118pro-sh',
    93 => 'eth-xg-118proac-sh', 94 => 'ethGe114ProVmSH',
    95 => 'ethGe104', 96 => 'eth-xg-120pro-sh'
};

sub get_secondary_states {
    my (%options) = @_;

    my @bits_str = split //, unpack('B*', $options{state});
    my $results = [];
    foreach (keys %$bits_secondary_state) {
        if ($bits_str[$_]) {
            push @$results, $bits_secondary_state->{$_};
        }
    }

    return $results;
}

1;
