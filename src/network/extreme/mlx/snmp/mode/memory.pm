#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package network::extreme::mlx::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-utilization', nlabel => 'memory.utilization.percentage', set => {
            key_values      => [ { name => 'memory_usage' } ],
            output_template => 'memory usage is: %.2f%%',
            perfdatas       => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_agentCurrentMemoryUtilization = '.1.3.6.1.4.1.1991.1.1.2.12.4.1.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids         => [ $oid_agentCurrentMemoryUtilization ],
        nothing_quit => 1
    );

    $self->{memory} = { memory_usage => $snmp_result->{$oid_agentCurrentMemoryUtilization} };
}

1;

__END__

=head1 MODE

Check Memory usage.

=over 8

=item B<--warning-memory-utilization>

Warning threshold in percent.

=item B<--critical-memory-utilization>

Critical threshold in percent.

=back

=cut
