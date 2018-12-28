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

package cloud::microsoft::office365::exchange::mode::emailactivity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_mailbox_output {
    my ($self, %options) = @_;
    
    return "User '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'mailboxes', type => 1, cb_prefix_output => 'prefix_mailbox_output', message_multiple => 'All email activity are ok' },
    ];
    
    $self->{maps_counters}->{mailboxes} = [
        { label => 'send-count', set => {
                key_values => [ { name => 'send_count' }, { name => 'name' } ],
                output_template => 'Send Count: %d',
                perfdatas => [
                    { label => 'send_count', value => 'send_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'receive-count', set => {
                key_values => [ { name => 'receive_count' }, { name => 'name' } ],
                output_template => 'Receive Count: %d',
                perfdatas => [
                    { label => 'receive_count', value => 'receive_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'read-count', set => {
                key_values => [ { name => 'read_count' }, { name => 'name' } ],
                output_template => 'Read Count: %d',
                perfdatas => [
                    { label => 'read_count', value => 'read_count_absolute', template => '%d',
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
                                    "filter-mailbox:s"      => { name => 'filter_mailbox' },
                                    "active-only"           => { name => 'active_only' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{mailboxes} = {};

    my $results = $options{custom}->office_get_exchange_activity();

    foreach my $mailbox (@{$results}) {
        if (defined($self->{option_results}->{filter_mailbox}) && $self->{option_results}->{filter_mailbox} ne '' &&
            $mailbox->{'User Principal Name'} !~ /$self->{option_results}->{filter_mailbox}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $mailbox->{'User Principal Name'} . "': no matching filter name.", debug => 1);
            next;
        }
        if ($self->{option_results}->{active_only} && defined($mailbox->{'Last Activity Date'}) && $mailbox->{'Last Activity Date'} eq '') {
            $self->{output}->output_add(long_msg => "skipping  '" . $mailbox->{'User Principal Name'} . "': no activity.", debug => 1);
            next;
        }

        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{name} = $mailbox->{'User Principal Name'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{send_count} = $mailbox->{'Send Count'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{receive_count} = $mailbox->{'Receive Count'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{read_count} = $mailbox->{'Read Count'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{last_activity_date} = $mailbox->{'Last Activity Date'};
    }
    
    if (scalar(keys %{$self->{mailboxes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check email activity (reporting period over the last 7 days).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/email-activity?view=o365-worldwide)

=over 8

=item B<--filter-mailbox>

Filter mailboxes.

=item B<--warning-*>

Threshold warning.
Can be: 'send-count', 'receive-count', 'read-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'send-count', 'receive-count', 'read-count'.

=item B<--active-only>

Filter only active entries ('Last Activity' set).

=back

=cut
