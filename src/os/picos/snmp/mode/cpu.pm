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

package os::picos::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu-usage', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'CPU Usage %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'temperature', nlabel => 'cpu.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'CPU Temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_cpuUsage = '.1.3.6.1.4.1.35098.1.1.0';
    my $oid_cpuTemperature = '.1.3.6.1.4.1.35098.1.6.0';

    my $oids = [$oid_cpuUsage, $oid_cpuTemperature];
    my $snmp_result = $options{snmp}->get_leef(oids => $oids, nothing_quit => 1);

    $self->{global} = { prct_used => $snmp_result->{$oid_cpuUsage},
                        temperature => $snmp_result->{$oid_cpuTemperature} =~ s/\s\C.*//r
    };
}

1;

__END__

=head1 MODE

Check CPU usage and temperature.

=over 8

=item B<--warning-cpu-usage>

Warning threshold for CPU usage in percentage.

=item B<--critical-cpu-usage>

Critical threshold for CPU usage in percentage.

=item B<--warning-temperature>

Warning threshold in celsius degrees for CPU.

=item B<--critical-temperature>

Critical threshold in celsius degrees for CPU.

=back

=cut
