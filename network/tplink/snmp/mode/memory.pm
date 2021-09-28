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

package network::tplink::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_message_output {
    my ($self, %options) = @_;

    return "Memory unit '" . $options{instance_value}->{unit_number} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_message_output', message_multiple => 'All memory units are ok' },
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage-prct', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
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

    my $oid_memory_used = '.1.3.6.1.4.1.11863.6.4.1.2.1.1.2'; # tpSysMonitorMemoryUtilization
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_memory_used,
        nothing_quit => 1
    );

    $self->{memory} = {};
    foreach (keys %$snmp_result) {
        /^$oid_memory_used\.(.*)$/;
        my $unit_number = $1;

        $self->{memory}->{$unit_number} = {
            unit_number => $unit_number,
            prct_used => $snmp_result->{$_}
        };
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage-prct' (%).

=back

=cut
