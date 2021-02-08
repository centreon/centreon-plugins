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

package cloud::microsoft::office365::exchange::mode::mailboxusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::Local;

sub custom_active_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{result_values}->{report_date} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/;
    $self->{output}->perfdata_add(label => 'perfdate', value => timelocal(0,0,12,$3,$2-1,$1-1900));

    $self->{output}->perfdata_add(label => 'active_mailboxes', nlabel => 'exchange.mailboxes.active.count',
                                  value => $self->{result_values}->{active},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  unit => 'mailboxes', min => 0, max => $self->{result_values}->{total});
}

sub custom_active_threshold {
    my ($self, %options) = @_;

    my $threshold_value = $self->{result_values}->{active};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_active};
    }
    my $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;

}

sub custom_active_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Active mailboxes on %s : %d/%d (%.2f%%)",
                        $self->{result_values}->{report_date},
                        $self->{result_values}->{active},
                        $self->{result_values}->{total},
                        $self->{result_values}->{prct_active});
    return $msg;
}

sub custom_active_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_active'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{report_date} = $options{new_datas}->{$self->{instance} . '_report_date'};
    $self->{result_values}->{prct_active} = ($self->{result_values}->{total} != 0) ? $self->{result_values}->{active} * 100 / $self->{result_values}->{total} : 0;

    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    
    $self->{output}->perfdata_add(label => 'used' . $extra_label, nlabel => $self->{result_values}->{display} . '#exchange.mailboxes.usage.bytes',
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
        
        if (defined($self->{instance_mode}->{option_results}->{critical_status}) && $self->{instance_mode}->{option_results}->{critical_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_status}) && $self->{instance_mode}->{option_results}->{warning_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_status}") {
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

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total ";
}

sub prefix_mailbox_output {
    my ($self, %options) = @_;
    
    return "Mailbox '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'active', type => 0 },
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'mailboxes', type => 1, cb_prefix_output => 'prefix_mailbox_output', message_multiple => 'All mailboxes usage are ok' },
    ];
    
    $self->{maps_counters}->{active} = [
        { label => 'active-mailboxes', set => {
                key_values => [ { name => 'active' }, { name => 'total' }, { name => 'report_date' } ],
                closure_custom_calc => $self->can('custom_active_calc'),
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_threshold_check => $self->can('custom_active_threshold'),
                closure_custom_perfdata => $self->can('custom_active_perfdata')
            }
        },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-usage-active', nlabel => 'exchange.mailboxes.active.usage.total.bytes', set => {
                key_values => [ { name => 'storage_used_active' } ],
                output_template => 'Usage (active mailboxes): %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_usage_active', value => 'storage_used_active', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'total-usage-inactive', nlabel => 'exchange.mailboxes.inactive.usage.total.bytes', set => {
                key_values => [ { name => 'storage_used_inactive' } ],
                output_template => 'Usage (inactive mailboxes): %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_usage_inactive', value => 'storage_used_inactive', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
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
        { label => 'items', nlabel => 'exchange.mailboxes.items.count', set => {
                key_values => [ { name => 'items' }, { name => 'name' } ],
                output_template => 'Items: %d',
                perfdatas => [
                    { label => 'items', value => 'items', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-mailbox:s"      => { name => 'filter_mailbox' },
        "warning-status:s"      => { name => 'warning_status', default => '%{used} > %{issue_warning_quota}' },
        "critical-status:s"     => { name => 'critical_status', default => '%{used} > %{prohibit_send_quota}' },
        "units:s"               => { name => 'units', default => '%' },
        "filter-counters:s"     => { name => 'filter_counters', default => 'active|total' }, 
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{active} = { active => 0, total => 0, report_date => '' };
    $self->{global} = { storage_used_active => 0, storage_used_inactive => 0 };
    $self->{mailboxes} = {};

    my $results = $options{custom}->office_get_exchange_mailbox_usage(param => "period='D7'");
    my $results_daily = [];
    if (scalar(@{$results})) {
       $self->{active}->{report_date} = @{$results}[0]->{'Report Refresh Date'};
       #$results_daily = $options{custom}->office_get_exchange_mailbox_usage(param => "date=" . $self->{active}->{report_date});
    }

    foreach my $mailbox (@{$results}, @{$results_daily}) {
        if (defined($self->{option_results}->{filter_mailbox}) && $self->{option_results}->{filter_mailbox} ne '' &&
            $mailbox->{'User Principal Name'} !~ /$self->{option_results}->{filter_mailbox}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $mailbox->{'User Principal Name'} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{active}->{total}++;

        if (!defined($mailbox->{'Last Activity Date'}) || ($mailbox->{'Last Activity Date'} ne $self->{active}->{report_date})) {
            $self->{global}->{storage_used_inactive} += ($mailbox->{'Storage Used (Byte)'} ne '') ? $mailbox->{'Storage Used (Byte)'} : 0;
            $self->{output}->output_add(long_msg => "skipping '" . $mailbox->{'User Principal Name'} . "': no activity.", debug => 1);
            next;
        }

        $self->{active}->{active}++;
        
        $self->{global}->{storage_used_active} += ($mailbox->{'Storage Used (Byte)'} ne '') ? $mailbox->{'Storage Used (Byte)'} : 0;

        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{name} = $mailbox->{'User Principal Name'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{storage_used} = ($mailbox->{'Storage Used (Byte)'} ne '') ? $mailbox->{'Storage Used (Byte)'} : 0;
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{issue_warning_quota} = $mailbox->{'Issue Warning Quota (Byte)'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{prohibit_send_quota} = $mailbox->{'Prohibit Send Quota (Byte)'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{prohibit_send_receive_quota} = $mailbox->{'Prohibit Send/Receive Quota (Byte)'};
        $self->{mailboxes}->{$mailbox->{'User Principal Name'}}->{items} = ($mailbox->{'Item Count'} ne '') ? $mailbox->{'Item Count'} : 0;
    }
}

1;

__END__

=head1 MODE

Check mailbox usage (reporting period over the last refreshed day).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/mailbox-usage?view=o365-worldwide)

=over 8

=item B<--filter-mailbox>

Filter mailboxes.

=item B<--warning-*>

Threshold warning.
Can be: 'active-mailboxes', 'total-usage-active' (count),
'total-usage-inactive' (count).

=item B<--critical-*>

Threshold critical.
Can be: 'active-mailboxes', 'total-usage-active' (count),
'total-usage-inactive' (count).

=item B<--warning-status>

Set warning threshold for status (Default: '%{used} > %{issue_warning_quota}').
Can used special variables like: %{used}, %{issue_warning_quota},
%{prohibit_send_quota}, %{prohibit_send_receive_quota}

=item B<--critical-status>

Set critical threshold for status (Default: '%{used} > %{prohibit_send_quota}').
Can used special variables like: %{used}, %{issue_warning_quota},
%{prohibit_send_quota}, %{prohibit_send_receive_quota}

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to hide per user counters: --filter-counters='active|total'
(Default: 'active|total')

=item B<--units>

Unit of thresholds (Default: '%') ('%', 'count').

=back

=cut
