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

package network::lenovo::rackswitch::snmp::mode::resources;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(find_rackswitch_branch);

my $branches = {
    'g8124'   => '.1.3.6.1.4.1.26543.2.7.4',
    'g7028'   => '.1.3.6.1.4.1.20301.2.7.17',
    'g7052'   => '.1.3.6.1.4.1.20301.2.7.18',
    'g8052'   => '.1.3.6.1.4.1.26543.2.7.7',
    'g8264cs' => '.1.3.6.1.4.1.20301.2.7.15',
    # g8264cs_sif not same oids
    'g8254'   => '.1.3.6.1.4.1.26543.2.7.6', # there is some extra stack OIDs
    'g8272'   => '.1.3.6.1.4.1.19046.2.7.24',
    'g8296'   => '.1.3.6.1.4.1.19046.2.7.22',
    'g8332'   => '.1.3.6.1.4.1.20301.2.7.16'
    
};

sub find_rackswitch_branch {
    my (%options) = @_;

    my $oid_software = '1.1.1.10.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_ . '.' . $oid_software, values(%$branches)) ]
    );
    foreach (keys %$snmp_result) {
        return $1 if (defined($snmp_result->{$_}) && /^(.*)\.$oid_software/);
    }

    $options{output}->add_option_msg(short_msg => 'unsupported device');
    $options{output}->option_exit();
}

1;

__END__
