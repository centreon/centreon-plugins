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

package apps::cisco::cms::restapi::mode::calls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active-calls', set => {
                key_values => [ { name => 'calls' } ],
                output_template => 'Active calls: %d',
                perfdatas => [
                    { label => 'active_calls', value => 'calls', template => '%d',
                      min => 0, unit => 'calls' },
                ],
            }
        },
        { label => 'local-participants', set => {
                key_values => [ { name => 'numParticipantsLocal' } ],
                output_template => 'Local participants: %d',
                perfdatas => [
                    { label => 'local_participants', value => 'numParticipantsLocal', template => '%d',
                      min => 0, unit => 'participants' },
                ],
            }
        },
        { label => 'remote-participants', set => {
                key_values => [ { name => 'numParticipantsRemote' } ],
                output_template => 'Remote participants: %d',
                perfdatas => [
                    { label => 'remote_participants', value => 'numParticipantsRemote', template => '%d',
                      min => 0, unit => 'participants' },
                ],
            }
        },
        { label => 'call-legs', set => {
                key_values => [ { name => 'numCallLegs' } ],
                output_template => 'Call legs: %d',
                perfdatas => [
                    { label => 'call_legs', value => 'numCallLegs', template => '%d',
                      min => 0, unit => 'legs' },
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
                                    "filter-counters:s"     => { name => 'filter_counters' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(method => '/calls');

    $self->{global} = { calls => 0, numParticipantsLocal => 0, numParticipantsRemote => 0 , numCallLegs => 0 };

    $self->{global}->{calls} = $results->{total};

    foreach my $call (@{$results->{call}}) {
        my $result = $options{custom}->get_endpoint(method => '/calls/' . $call->{id});
        $self->{global}->{numParticipantsLocal} += $result->{numParticipantsLocal};
        $self->{global}->{numParticipantsRemote} += $result->{numParticipantsRemote};
        $self->{global}->{numCallLegs} += $result->{numCallLegs};
    }
}

1;

__END__

=head1 MODE

Check number of calls and participants.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='calls')

=item B<--warning-*>

Threshold warning.
Can be: 'active-calls', 'local-participants', 'remote-participants',
'call-legs'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-calls', 'local-participants', 'remote-participants',
'call-legs'.

=back

=cut
