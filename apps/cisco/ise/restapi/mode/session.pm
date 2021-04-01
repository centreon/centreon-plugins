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

package apps::cisco::ise::restapi::mode::session;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active-sessions', nlabel => 'sessions.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active sessions: %d',
                perfdatas => [
                    { label => 'active_sessions', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'postured-endpoints', nlabel => 'endpoints.postured.count', set => {
                key_values => [ { name => 'postured' } ],
                output_template => 'Postured endpoints: %d',
                perfdatas => [
                    { label => 'postured_endpoints', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'profiler-service-sessions', nlabel => 'sessions.profiler.count', set => {
                key_values => [ { name => 'profiler' } ],
                output_template => 'Profiler service sessions: %d',
                perfdatas => [
                    { label => 'profiler_service_sessions', template => '%d', min => 0 }
                ]
            }
        }
    ];
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

    my $active = $options{custom}->get_endpoint(category => '/Session/ActiveCount');
    my $posture = $options{custom}->get_endpoint(category => '/Session/PostureCount');
    my $profiler = $options{custom}->get_endpoint(category => '/Session/ProfilerCount');

    $self->{global} = '';

    $self->{global} = {
        active => $active->{count},
        postured => $posture->{count},
        profiler => $profiler->{count},
    };
}

1;

__END__

=head1 MODE

Check sessions counters.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='active')

=item B<--warning-*>

Threshold warning.
Can be: 'active-sessions', 'postured-endpoints', 'profiler-service-sessions'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-sessions', 'postured-endpoints', 'profiler-service-sessions'.

=back

=cut
