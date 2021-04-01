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

package network::colubris::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_output' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'current', set => {
                key_values => [ { name => 'usage_now' } ],
                output_template => '%.2f %% (current)',
                perfdatas => [
                    { label => 'cpu_current', value => 'usage_now', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => '5s', set => {
                key_values => [ { name => 'usage_5s' } ],
                output_template => '%.2f %% (5sec)',
                perfdatas => [
                    { label => 'cpu_5s', value => 'usage_5s', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => '10s', set => {
                key_values => [ { name => 'usage_10s' } ],
                output_template => '%.2f %% (10sec)',
                perfdatas => [
                    { label => 'cpu_10s', value => 'usage_10s', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => '20s', set => {
                key_values => [ { name => 'usage_20s' } ],
                output_template => '%.2f %% (5sec)',
                perfdatas => [
                    { label => 'cpu_20s', value => 'usage_20s', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
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

    my $oid_coUsInfoCpuUseNow = '.1.3.6.1.4.1.8744.5.21.1.1.5.0';
    my $oid_coUsInfoCpuUse5Sec = '.1.3.6.1.4.1.8744.5.21.1.1.6.0';
    my $oid_coUsInfoCpuUse10Sec = '.1.3.6.1.4.1.8744.5.21.1.1.7.0';
    my $oid_coUsInfoCpuUse20Sec = '.1.3.6.1.4.1.8744.5.21.1.1.8.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_coUsInfoCpuUseNow, $oid_coUsInfoCpuUse5Sec,
            $oid_coUsInfoCpuUse10Sec, $oid_coUsInfoCpuUse20Sec
        ],
        nothing_quit => 1
    );

    $self->{global} = { 
        usage_now => $snmp_result->{$oid_coUsInfoCpuUseNow},
        usage_5s => $snmp_result->{$oid_coUsInfoCpuUse5Sec},
        usage_10s => $snmp_result->{$oid_coUsInfoCpuUse10Sec},
        usage_20s => $snmp_result->{$oid_coUsInfoCpuUse20Sec},
    };
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='20s'

=item B<--warning-*>

Threshold warning.
Can be: 'current', '5s', '10s', '20s'.

=item B<--critical-*>

Threshold critical.
Can be: 'current', '5s', '10s', '20s'.

=back

=cut
