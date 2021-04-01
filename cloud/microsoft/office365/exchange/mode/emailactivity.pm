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

package cloud::microsoft::office365::exchange::mode::emailactivity;

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

    $self->{output}->perfdata_add(label => 'active_users', nlabel => 'exchange.users.active.count',
                                  value => $self->{result_values}->{active},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  unit => 'users', min => 0, max => $self->{result_values}->{total});
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

    my $msg = sprintf("Active users on %s : %d/%d (%.2f%%)",
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

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total (active users) ";
}

sub prefix_mailbox_output {
    my ($self, %options) = @_;
    
    return "User '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'active', type => 0 },
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'users', type => 1, cb_prefix_output => 'prefix_mailbox_output', message_multiple => 'All email activity are ok' },
    ];
    
    $self->{maps_counters}->{active} = [
        { label => 'active-users', set => {
                key_values => [ { name => 'active' }, { name => 'total' }, { name => 'report_date' } ],
                closure_custom_calc => $self->can('custom_active_calc'),
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_threshold_check => $self->can('custom_active_threshold'),
                closure_custom_perfdata => $self->can('custom_active_perfdata')
            }
        },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-send-count', nlabel => 'exchange.users.emails.sent.total.count', set => {
                key_values => [ { name => 'send_count' } ],
                output_template => 'Send Count: %d',
                perfdatas => [
                    { label => 'total_send_count', value => 'send_count', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-receive-count', nlabel => 'exchange.users.emails.received.total.count', set => {
                key_values => [ { name => 'receive_count' } ],
                output_template => 'Receive Count: %d',
                perfdatas => [
                    { label => 'total_receive_count', value => 'receive_count', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-read-count', nlabel => 'exchange.users.emails.read.total.count', set => {
                key_values => [ { name => 'read_count' } ],
                output_template => 'Read Count: %d',
                perfdatas => [
                    { label => 'total_read_count', value => 'read_count', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{users} = [
        { label => 'send-count', nlabel => 'exchange.users.emails.sent.count', set => {
                key_values => [ { name => 'send_count' }, { name => 'name' } ],
                output_template => 'Send Count: %d',
                perfdatas => [
                    { label => 'send_count', value => 'send_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'receive-count', nlabel => 'exchange.users.emails.received.count', set => {
                key_values => [ { name => 'receive_count' }, { name => 'name' } ],
                output_template => 'Receive Count: %d',
                perfdatas => [
                    { label => 'receive_count', value => 'receive_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'read-count', nlabel => 'exchange.users.emails.read.count', set => {
                key_values => [ { name => 'read_count' }, { name => 'name' } ],
                output_template => 'Read Count: %d',
                perfdatas => [
                    { label => 'read_count', value => 'read_count', template => '%d',
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
        "filter-user:s"         => { name => 'filter_user' },
        "units:s"               => { name => 'units', default => '%' },
        "filter-counters:s"     => { name => 'filter_counters', default => 'active|total' }, 
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{active} = { active => 0, total => 0, report_date => '' };
    $self->{global} = { send_count => 0, receive_count => 0 , read_count => 0 };
    $self->{users} = {};

    my $results = $options{custom}->office_get_exchange_activity(param => "period='D7'");
    my $results_daily = [];
    if (scalar(@{$results})) {
       $self->{active}->{report_date} = @{$results}[0]->{'Report Refresh Date'};
       $results_daily = $options{custom}->office_get_exchange_activity(param => "date=" . $self->{active}->{report_date});
    }

    foreach my $user (@{$results}, @{$results_daily}) {
        if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
            $user->{'User Principal Name'} !~ /$self->{option_results}->{filter_user}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $user->{'User Principal Name'} . "': no matching filter name.", debug => 1);
            next;
        }

        if ($user->{'Report Period'} != 1) {
            if (!defined($user->{'Last Activity Date'}) || ($user->{'Last Activity Date'} ne $self->{active}->{report_date})) {
                $self->{output}->output_add(long_msg => "skipping '" . $user->{'User Principal Name'} . "': no activity.", debug => 1);
            }
            $self->{active}->{total}++;
            next;
        }

        $self->{active}->{active}++;

        $self->{global}->{send_count} += $user->{'Send Count'};
        $self->{global}->{receive_count} += $user->{'Receive Count'};
        $self->{global}->{read_count} += $user->{'Read Count'};

        $self->{users}->{$user->{'User Principal Name'}}->{name} = $user->{'User Principal Name'};
        $self->{users}->{$user->{'User Principal Name'}}->{send_count} = $user->{'Send Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{receive_count} = $user->{'Receive Count'};
        $self->{users}->{$user->{'User Principal Name'}}->{read_count} = $user->{'Read Count'};
    }
}

1;

__END__

=head1 MODE

Check email activity (reporting period over the last refreshed day).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/email-activity?view=o365-worldwide)

=over 8

=item B<--filter-user>

Filter users.

=item B<--warning-*>

Threshold warning.
Can be: 'active-users', 'total-send-count' (count),
'total-receive-count' (count), 'total-read-count' (count),
'send-count' (count), 'receive-count' (count), 'read-count' (count).

=item B<--critical-*>

Threshold critical.
Can be: 'active-users', 'total-send-count' (count),
'total-receive-count' (count), 'total-read-count' (count),
'send-count' (count), 'receive-count' (count), 'read-count' (count).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to hide per user counters: --filter-counters='active|total'
(Default: 'active|total')

=item B<--units>

Unit of thresholds (Default: '%') ('%', 'count').

=back

=cut
