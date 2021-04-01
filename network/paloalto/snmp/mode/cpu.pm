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

package network::paloalto::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'managementplane', nlabel => 'cpu.managementplane.utilization.percentage', set => {
                key_values => [ { name => 'managementplane' } ],
                output_template => 'management plane usage is: %.2f %%',
                perfdatas => [
                    { value => 'managementplane', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'dataplane', nlabel => 'cpu.dataplane.utilization.percentage', set => {
                key_values => [ { name => 'dataplane' } ],
                output_template => 'dataplane usage is: %.2f %%',
                perfdatas => [
                    { value => 'dataplane', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        }
    ];
}

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return 'CPU ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_managementplane = '.1.3.6.1.2.1.25.3.3.1.2.1';
    my $oid_dataplane = '.1.3.6.1.2.1.25.3.3.1.2.2';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_managementplane, $oid_dataplane]);
    $self->{cpu_avg} = {
        dataplane => $snmp_result->{$oid_dataplane},
        managementplane => $snmp_result->{$oid_managementplane}
    };
}

1;

__END__

=head1 MODE

Check system CPUs (HOST-RESOURCES-MIB)
(The average, over the last minute, of the percentage of time that this processor was not idle)

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'managementplane' (%), 'dataplane' (%).

=back

=cut
