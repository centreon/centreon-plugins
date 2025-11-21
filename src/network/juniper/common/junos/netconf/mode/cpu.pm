#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::netconf::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_message_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{name} . "' average usage: ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_message_output', message_multiple => 'All CPU usages are ok' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
            key_values      => [ { name => 'cpu_1min_avg' } ],
            output_template => '%.2f %% (1m)',
            perfdatas       => [
                { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
            key_values      => [ { name => 'cpu_5min_avg' } ],
            output_template => '%.2f %% (5m)',
            perfdatas       => [
                { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
            ]
        }
        },
        { label => 'average-15m', nlabel => 'cpu.utilization.15m.percentage', set => {
            key_values      => [ { name => 'cpu_15min_avg' } ],
            output_template => '%.2f %% (15m)',
            perfdatas       => [
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_cpu_infos();

    $self->{cpu} = {};
    foreach (@$result) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                 $_->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{cpu}->{ $_->{name} } = $_;
    }
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--filter-name>

Filter CPU by name.

=item B<--warning-average-1m>

Warning threshold for 1 minute average CPU usage (%).

=item B<--critical-average-1m>

Critical threshold for 1 minute average CPU usage (%).

=item B<--warning-average-5m>

Warning threshold for 5 minutes average CPU usage (%).

=item B<--critical-average-5m>

Critical threshold for 5 minutes average CPU usage (%).

=item B<--warning-average-15m>

Warning threshold for 15 minutes average CPU usage (%).

=item B<--critical-average-15m>

Critical threshold for 15 minutes average CPU usage (%).

=back

=cut
