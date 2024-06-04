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

package apps::eclipse::mosquitto::mqtt::mode::clients;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Time::HiRes qw(time);
use POSIX qw(floor);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'clients.connected', nlabel => 'clients.connected.count', set => {
            key_values      => [{ name => 'connected' }],
            output_template => 'Connected clients: %d',
            perfdatas       => [
                { label => 'connected_clients', template => '%d',
                  min   => 0 }
            ]
        }
        },
        { label => 'clients.max', nlabel => 'clients.max.count', set => {
            key_values      => [{ name => 'maximum' }],
            output_template => 'Maximum connected clients: %d',
            perfdatas       => [
                { label => 'max_clients', template => '%d',
                  min   => 0 }
            ]
        }
        },
        { label => 'clients.active', nlabel => 'clients.active.count', set => {
            key_values      => [{ name => 'active' }],
            output_template => 'Active clients: %d',
            perfdatas       => [
                { label => 'active_clients', template => '%d',
                  min   => 0 }
            ]
        }
        },
        { label => 'clients.inactive', nlabel => 'clients.inactive.count', set => {
            key_values      => [{ name => 'inactive' }],
            output_template => 'Inactive clients: %d',
            perfdatas       => [
                { label => 'inactive_clients', template => '%d',
                  min   => 0 }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = $options{mqtt}->queries(
        base_topic => '$SYS/broker/clients/',
        topics     => ['connected', 'maximum', 'active', 'inactive']
    );

    for my $topic (keys %results) {
        $self->{global}->{$topic} = $results{$topic};
    }
}

1;

__END__

=head1 MODE

Check system uptime.

=over 8

=item B<--warning-uptime>

Warning threshold.

=item B<--critical-uptime>

Critical threshold.

=item B<--unit>

Select the time unit for thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=back

=cut