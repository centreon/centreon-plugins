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

package cloud::microsoft::office365::exchange::mode::mailboxusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    
    $self->{output}->perfdata_add(label => 'used' . $extra_label,
                                  unit => 'B',
                                  value => $self->{result_values}->{used},
                                  min => 0);
}

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
            eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($issue_warning_quota_value, $issue_warning_quota_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{issue_warning_quota});
    my ($prohibit_send_quota_value, $prohibit_send_quota_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{prohibit_send_quota});
    my ($prohibit_send_receive_quota_value, $prohibit_send_receive_quota_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{prohibit_send_receive_quota});
    
    my $msg = sprintf("Used: %s Issue Warning Quota: %s Prohibit Send Quota: %s Prohibit Send/Receive Quota: %s", 
            $used_value . " " . $used_unit, 
            $issue_warning_quota_value . " " . $issue_warning_quota_unit, 
            $prohibit_send_quota_value . " " . $prohibit_send_quota_unit, 
            $prohibit_send_receive_quota_value . " " . $prohibit_send_receive_quota_unit);
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_storage_used'};
    $self->{result_values}->{issue_warning_quota} = $options{new_datas}->{$self->{instance} . '_issue_warning_quota'};
    $self->{result_values}->{prohibit_send_quota} = $options{new_datas}->{$self->{instance} . '_prohibit_send_quota'};
    $self->{result_values}->{prohibit_send_receive_quota} = $options{new_datas}->{$self->{instance} . '_prohibit_send_receive_quota'};
    return 0;
}

sub prefix_mailbox_output {
    my ($self, %options) = @_;
    
    return "Mailbox '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'mailboxes', type => 1, cb_prefix_output => 'prefix_mailbox_output', message_multiple => 'All mailboxes usage are ok' },
    ];
    
    $self->{maps_counters}->{mailboxes} = [
        { label => 'usage', set => {
                key_values => [ { name => 'storage_used' }, { name => 'issue_warning_quota' },
                    { name => 'prohibit_send_quota' }, { name => 'prohibit_send_receive_quota' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
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
                                    "filter-mailbox:s"          => { name => 'filter_mailbox' },
                                    "warning-status:s"          => { name => 'warning_status', default => '%{used} > %{issue_warning_quota}' },
                                    "critical-status:s"         => { name => 'critical_status', default => '%{used} > %{prohibit_send_quota}' },
                                    "active-only"               => { name => 'active_only' },
                                });
    
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
    $self->change_macros();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{mailboxes} = {};

    my $results = $options{custom}->office_get_exchange_mailbox_usage();

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
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{storage_used} = ($mailbox->{'Storage Used (Byte)'} ne '') ? $mailbox->{'Storage Used (Byte)'} : 0;
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{issue_warning_quota} = $mailbox->{'Issue Warning Quota (Byte)'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{prohibit_send_quota} = $mailbox->{'Prohibit Send Quota (Byte)'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{prohibit_send_receive_quota} = $mailbox->{'Prohibit Send/Receive Quota (Byte)'};
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

Check mailbox usage (reporting period over the last 7 days).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/mailbox-usage?view=o365-worldwide)

=over 8

=item B<--filter-mailbox>

Filter mailboxes.

=item B<--warning-status>

Set warning threshold for status (Default: '%{used} > %{issue_warning_quota}').
Can used special variables like: %{used}, %{issue_warning_quota}, %{prohibit_send_quota}, %{prohibit_send_receive_quota}

=item B<--critical-status>

Set critical threshold for status (Default: '%{used} > %{prohibit_send_quota}').
Can used special variables like: %{used}, %{issue_warning_quota}, %{prohibit_send_quota}, %{prohibit_send_receive_quota}

=item B<--active-only>

Filter only active entries ('Last Activity' set).

=back

=cut
