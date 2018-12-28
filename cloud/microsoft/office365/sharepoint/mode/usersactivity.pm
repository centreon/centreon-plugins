#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::microsoft::office365::sharepoint::mode::usersactivity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_user_output {
    my ($self, %options) = @_;
    
    return "User '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'users', type => 1, cb_prefix_output => 'prefix_user_output', message_multiple => 'All users activity are ok' },
    ];
    
    $self->{maps_counters}->{users} = [
        { label => 'viewed-edited-file-count', set => {
                key_values => [ { name => 'viewed_edited_file_count' }, { name => 'name' } ],
                output_template => 'Viewed or Edited File Count: %d',
                perfdatas => [
                    { label => 'viewed_edited_file_count', value => 'viewed_edited_file_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'file-count', set => {
                key_values => [ { name => 'file_count' }, { name => 'name' } ],
                output_template => 'File Count: %d',
                perfdatas => [
                    { label => 'file_count', value => 'file_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'shared-int-file-count', set => {
                key_values => [ { name => 'shared_int_file_count' }, { name => 'name' } ],
                output_template => 'Shared Internally File Count: %d',
                perfdatas => [
                    { label => 'shared_int_file_count', value => 'shared_int_file_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'shared-ext-file-count', set => {
                key_values => [ { name => 'shared_ext_file_count' }, { name => 'name' } ],
                output_template => 'Shared Externally File Count: %d',
                perfdatas => [
                    { label => 'shared_ext_file_count', value => 'shared_ext_file_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'visited-page-count', set => {
                key_values => [ { name => 'visited_page_count' }, { name => 'name' } ],
                output_template => 'Visited Page Count: %d',
                perfdatas => [
                    { label => 'visited_page_count', value => 'visited_page_count_absolute', template => '%d',
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

    my $results = $options{custom}->office_get_sharepoint_activity();

    foreach my $user (@{$results}) {
        if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
            $user->{'User Principal Name'} !~ /$self->{option_results}->{filter_user}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $user->{'User Principal Name'} . "': no matching filter name.", debug => 1);
            next;
        }
        if ($self->{option_results}->{active_only} && defined($user->{'Last Activity Date'}) && $user->{'Last Activity Date'} eq '') {
            $self->{output}->output_add(long_msg => "skipping  '" . $user->{'User Principal Name'} . "': no activity.", debug => 1);
            next;
        }

        $self->{users}->{$user->{'User Principal Name'}}->{name} = $user->{'User Principal Name'};
        $self->{users}->{$user->{'User Principal Name'}}->{viewed_edited_file_count} = $user->{'Viewed Or Edited File Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{file_count} = $user->{'Synced File Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{shared_int_file_count} = $user->{'Shared Internally File Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{shared_ext_file_count} = $user->{'Shared Externally File Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{visited_page_count} = $user->{'Visited Page Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{last_activity_date} = $user->{'Last Activity Date'};
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
https://docs.microsoft.com/en-us/office365/admin/activity-reports/sharepoint-activity?view=o365-worldwide)

=over 8

=item B<--filter-user>

Filter users.

=item B<--warning-*>

Threshold warning.
Can be: 'viewed-edited-file-count', 'file-count', 'shared-int-file-count',
'shared-ext-file-count', 'visited-page-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'viewed-edited-file-count', 'file-count', 'shared-int-file-count',
'shared-ext-file-count', 'visited-page-count'.

=item B<--active-only>

Filter only active entries ('Last Activity' set).

=back

=cut
