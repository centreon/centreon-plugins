#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package cloud::microsoft::office365::skype::mode::devicesusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_active_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => 'active_users',
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
    
    return "Users count by device type : ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'active', type => 0 },
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
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
        { label => 'windows', set => {
                key_values => [ { name => 'windows' } ],
                output_template => 'Windows: %d',
                perfdatas => [
                    { label => 'windows', value => 'windows', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'ipad', set => {
                key_values => [ { name => 'ipad' } ],
                output_template => 'iPad: %d',
                perfdatas => [
                    { label => 'ipad', value => 'ipad', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'iphone', set => {
                key_values => [ { name => 'iphone' } ],
                output_template => 'iPhone: %d',
                perfdatas => [
                    { label => 'iphone', value => 'iphone', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'android-phone', set => {
                key_values => [ { name => 'android_phone' } ],
                output_template => 'Android Phone: %d',
                perfdatas => [
                    { label => 'android_phone', value => 'android_phone', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'windows-phone', set => {
                key_values => [ { name => 'windows_phone' } ],
                output_template => 'Windows Phone: %d',
                perfdatas => [
                    { label => 'windows_phone', value => 'windows_phone', template => '%d',
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
    
    $options{options}->add_options(arguments => {
        "filter-user:s"     => { name => 'filter_user' },
        "units:s"           => { name => 'units', default => '%' },
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{active} = { active => 0, total => 0, report_date => '' };
    $self->{global} = { windows => 0, ipad => 0, iphone => 0, android_phone => 0, windows_phone => 0 };

    my $results = $options{custom}->office_get_skype_device_usage();

    foreach my $user (@{$results}) {
        $self->{active}->{report_date} = $user->{'Report Refresh Date'} if ($self->{active}->{report_date} eq '');

        if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
            $user->{'User Principal Name'} !~ /$self->{option_results}->{filter_user}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $user->{'User Principal Name'} . "': no matching filter name.", debug => 1);
            next;
        }
    
        $self->{active}->{total}++;

        if (!defined($user->{'Last Activity Date'}) || $user->{'Last Activity Date'} eq '' ||
            ($user->{'Last Activity Date'} ne $user->{'Report Refresh Date'})) {
            $self->{output}->output_add(long_msg => "skipping '" . $user->{'User Principal Name'} . "': no activity.", debug => 1);
            next;
        }

        $self->{active}->{active}++;

        $self->{global}->{windows}++ if ($user->{'Used Windows'} =~ /Yes/);
        $self->{global}->{ipad}++ if ($user->{'Used iPad'} =~ /Yes/);
        $self->{global}->{iphone}++ if ($user->{'Used iPhone'} =~ /Yes/);
        $self->{global}->{android_phone}++ if ($user->{'Used Android Phone'} =~ /Yes/);
        $self->{global}->{windows_phone}++ if ($user->{'Used Windows Phone'} =~ /Yes/);
    }
}

1;

__END__

=head1 MODE

Check devices usage (reporting period over the last 7 days).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/microsoft-teams-device-usage?view=o365-worldwide)

=over 8

=item B<--filter-user>

Filter users.

=item B<--warning-*>

Threshold warning.
Can be: 'active-users', 'windows' (count), 'ipad' (count),
'iphone' (count), 'android-phone' (count),
'windows-phone' (count).

=item B<--critical-*>

Threshold critical.
Can be: 'active-users', 'windows' (count), 'ipad' (count),
'iphone' (count), 'android-phone' (count),
'windows-phone' (count).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to hide per user counters: --filter-counters='windows'

=item B<--units>

Unit of thresholds (Default: '%') ('%', 'count').

=back

=cut
