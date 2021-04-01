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

package apps::centreon::map::jmx::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active-session', set => {
                key_values => [ { name => 'SessionCount' } ],
                output_template => 'Active Sessions: %d',
                perfdatas => [
                    { label => 'active_sessions', value => 'SessionCount', template => '%d',
                      min => 0, unit => 'sessions' },
                ],
            }
        },
        { label => 'queue-size', set => {
                key_values => [ { name => 'AverageEventQueueSize' } ],
                output_template => 'Average Event Queue Size: %d',
                perfdatas => [
                    { label => 'queue_size', value => 'AverageEventQueueSize', template => '%d',
                      min => 0 },
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
                                    "filter-counters:s"     => { name => 'filter_counters', default => '' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mbean_session = "com.centreon.studio.map:type=session,name=statistics";

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
        { mbean => $mbean_session }
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 0);

    $self->{global} = {};

    $self->{global} = {
        SessionCount => $result->{$mbean_session}->{SessionCount},
        AverageEventQueueSize => $result->{$mbean_session}->{AverageEventQueueSize},
    };
}

1;

__END__

=head1 MODE

Check active sessions count and the number of whatsup events by user session (queue size).

Example:

perl centreon_plugins.pl --plugin=apps::centreon::map::jmx::plugin --custommode=jolokia
--url=http://10.30.2.22:8080/jolokia-war --mode=sessions

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='session')

=item B<--warning-*>

Threshold warning.
Can be: 'active-session', 'queue-size'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-session', 'queue-size'.

=back

=cut

