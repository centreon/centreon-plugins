#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::microsoft::office365::teams::mode::usersactivity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total ";
}

sub prefix_user_output {
    my ($self, %options) = @_;
    
    return "User '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'users', type => 1, cb_prefix_output => 'prefix_user_output', message_multiple => 'All users activity are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-team-chat', set => {
                key_values => [ { name => 'team_chat' } ],
                output_template => 'Team Chat Message Count: %d',
                perfdatas => [
                    { label => 'total_team_chat', value => 'team_chat_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-private-chat', set => {
                key_values => [ { name => 'private_chat' } ],
                output_template => 'Private Chat Message Count: %d',
                perfdatas => [
                    { label => 'total_private_chat', value => 'private_chat_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-call', set => {
                key_values => [ { name => 'call' } ],
                output_template => 'Call Count: %d',
                perfdatas => [
                    { label => 'total_call', value => 'call_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-meeting', set => {
                key_values => [ { name => 'meeting' } ],
                output_template => 'Meeting Count: %d',
                perfdatas => [
                    { label => 'total_meeting', value => 'meeting_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{users} = [
        { label => 'team-chat', set => {
                key_values => [ { name => 'team_chat' }, { name => 'name' } ],
                output_template => 'Team Chat Message Count: %d',
                perfdatas => [
                    { label => 'team_chat', value => 'team_chat_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'private-chat', set => {
                key_values => [ { name => 'private_chat' }, { name => 'name' } ],
                output_template => 'Private Chat Message Count: %d',
                perfdatas => [
                    { label => 'private_chat', value => 'private_chat_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'call', set => {
                key_values => [ { name => 'call' }, { name => 'name' } ],
                output_template => 'Call Count: %d',
                perfdatas => [
                    { label => 'call', value => 'call_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'meeting', set => {
                key_values => [ { name => 'meeting' }, { name => 'name' } ],
                output_template => 'Meeting Count: %d',
                perfdatas => [
                    { label => 'meeting', value => 'meeting_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'last-activity', threshold => 0, set => {
                key_values => [ { name => 'last_activity_date' }, { name => 'name' } ],
                output_template => 'Last Activity: %s',
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-counters:s" => { name => 'filter_counters' },
                                    "filter-user:s"     => { name => 'filter_user' },
                                    "active-only"       => { name => 'active_only' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{users} = {};

    my $results = $options{custom}->office_get_teams_activity();

    $self->{global} = { team_chat => 0, private_chat => 0, call => 0, meeting => 0 };

    foreach my $user (@{$results}) {
        if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
            $user->{'User Principal Name'} !~ /$self->{option_results}->{filter_user}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $user->{'User Principal Name'} . "': no matching filter name.", debug => 1);
            next;
        }
        if ($self->{option_results}->{active_only} && defined($user->{'Last Activity Date'}) && $user->{'Last Activity Date'} eq '') {
            $self->{output}->output_add(long_msg => "skipping '" . $user->{'User Principal Name'} . "': no activity.", debug => 1);
            next;
        }

        $self->{users}->{$user->{'User Principal Name'}}->{name} = $user->{'User Principal Name'};
        $self->{users}->{$user->{'User Principal Name'}}->{team_chat} = $user->{'Team Chat Message Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{private_chat} = $user->{'Private Chat Message Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{call} = $user->{'Call Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{meeting} = $user->{'Meeting Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{last_activity_date} = $user->{'Last Activity Date'};

        $self->{global}->{team_chat} += $user->{'Team Chat Message Count'};
        $self->{global}->{private_chat} += $user->{'Private Chat Message Count'};
        $self->{global}->{call} += $user->{'Call Count'};
        $self->{global}->{meeting} += $user->{'Meeting Count'};
    }
    
    if (scalar(keys %{$self->{users}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check users activity (reporting period over the last 7 days).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/microsoft-teams-user-activity?view=o365-worldwide)

=over 8

=item B<--filter-user>

Filter users.

=item B<--warning-*>

Threshold warning.
Can be: 'total-team-chat', 'total-private-chat', 'total-call',
'total-meeting', 'team-chat', 'private-chat', 'call', 'meeting'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-team-chat', 'total-private-chat', 'total-call',
'total-meeting', 'team-chat', 'private-chat', 'call', 'meeting'.

=item B<--active-only>

Filter only active entries ('Last Activity' set).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to hide per user counters: --filter-counters='total'

=back

=cut
