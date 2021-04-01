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

package network::audiocodes::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'voip', nlabel => 'cpu.voip.utilization.percentage', set => {
                key_values => [ { name => 'voip' } ],
                output_template => 'CPU VoIp Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu_voip', value => 'voip', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'data', nlabel => 'cpu.data.utilization.percentage', set => {
                key_values => [ { name => 'data' } ],
                output_template => 'CPU Data Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu_data', value => 'data', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_acSysStateVoIpCpuUtilization = '.1.3.6.1.4.1.5003.9.10.10.2.5.10.0';
    my $oid_acSysStateDataCpuUtilization = '.1.3.6.1.4.1.5003.9.10.10.2.5.8.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [
        $oid_acSysStateVoIpCpuUtilization, $oid_acSysStateDataCpuUtilization
    ], nothing_quit => 1);
    
    $self->{global} = { data => $snmp_result->{$oid_acSysStateDataCpuUtilization}, voip => $snmp_result->{$oid_acSysStateVoIpCpuUtilization} };
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^voip$'

=item B<--warning-*>

Threshold warning.
Can be: 'voip', 'data'.

=item B<--critical-*>

Threshold critical.
Can be: 'voip', 'data'.

=back

=cut
