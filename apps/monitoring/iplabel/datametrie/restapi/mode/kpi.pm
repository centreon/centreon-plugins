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

package apps::monitoring::iplabel::datametrie::restapi::mode::kpi;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status: %s', $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'kpi', type => 1, cb_prefix_output => 'prefix_kpi_output', message_multiple => 'All KPI are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{kpi} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'success-rate', nlabel => 'kpi.success.rate.percentage', set => {
                key_values => [ { name => 'success_rate', no_value => -1 }, { name => 'display' } ],
                output_template => 'success rate: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sla-availability', nlabel => 'kpi.sla.availability.percentage', set => {
                key_values => [ { name => 'sla_availability', no_value => -1 }, { name => 'display' } ],
                output_template => 'sla availability: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'performance', nlabel => 'kpi.performance.milliseconds', set => {
                key_values => [ { name => 'performance', no_value => -1 }, { name => 'display' } ],
                output_template => 'performance: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-id:s'       => { name => 'filter_id' },
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status', ]);
}

sub prefix_kpi_output {
    my ($self, %options) = @_;
    
    return "KPI '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(
        endpoint => '/Get_Monitors/',
        label => 'Get_Monitors'
    );

    $self->{kpi} = {};
    my $time = time();
    my $end_date = POSIX::strftime('%d/%m/%Y %H:%M:%S', gmtime());
    foreach (@$results) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{MONITOR_NAME} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping monitor '" . $_->{MONITOR_NAME} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $_->{MONITOR_ID} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping monitor '" . $_->{MONITOR_NAME} . "': no matching filter.", debug => 1);
            next;
        }

        my $start_date = POSIX::strftime('%d/%m/%Y %H:%M:%S', gmtime($time - ($_->{PERIODICITY} * 60 * 2)));
        my $kpi_detail = $options{custom}->request_api(
            endpoint => '/GMT/Get_KPI/',
            label => 'Get_KPI',
            get_param => [
                'monitor_id=' . $_->{MONITOR_ID},
                'date_value1=' . $start_date,
                'date_value2=' . $end_date
            ]
        );

        $self->{kpi}->{ $_->{MONITOR_NAME} } = {
            display => $_->{MONITOR_NAME},
            status => $_->{MONITOR_STATUS},
            success_rate => $kpi_detail->{SUCCESS_RATE},
            performance => $kpi_detail->{PERFORMANCE},
            sla_availability => $kpi_detail->{SLA_AVAILABILITY},
        };
    }

    if (scalar(keys %{$self->{kpi}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No monitor found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check KPI.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-id>

Filter by monitor id (can be a regexp).

=item B<--filter-name>

Filter by monitor name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'success-rate' (%) 'sla-availability' (%), 'performance' (ms).

=back

=cut
