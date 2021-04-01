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

package network::watchguard::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => '1min', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => '1min' } ],
                output_template => '1 minute: %.2f %%',
                perfdatas => [
                    { label => 'cpu_1min', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => '5min', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => '5min' } ],
                output_template => '5 minutes: %.2f %%',
                perfdatas => [
                    { label => 'cpu_5min', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => '15min', nlabel => 'cpu.utilization.15m.percentage', set => {
                key_values => [ { name => '15min' } ],
                output_template => '15 minutes: %.2f %%',
                perfdatas => [
                    { label => 'cpu_15min', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_wgSystemCpuUtil1 = '.1.3.6.1.4.1.3097.6.3.77.0';
    my $oid_wgSystemCpuUtil5 = '.1.3.6.1.4.1.3097.6.3.78.0';
    my $oid_wgSystemCpuUtil15 = '.1.3.6.1.4.1.3097.6.3.79.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_wgSystemCpuUtil1, $oid_wgSystemCpuUtil5, $oid_wgSystemCpuUtil15
        ], 
        nothing_quit => 1
    );

    $self->{global} = {
        '1min' => $snmp_result->{$oid_wgSystemCpuUtil1} / 100,
        '5min' => $snmp_result->{$oid_wgSystemCpuUtil5} / 100,
        '15min' => $snmp_result->{$oid_wgSystemCpuUtil15} / 100
    };
}

1;

__END__

=head1 MODE

Check CPU usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^1min|5min$'

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: '1min', '5min', '15min'.

=back

=cut
