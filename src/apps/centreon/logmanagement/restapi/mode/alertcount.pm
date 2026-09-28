#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::centreon::logmanagement::restapi::mode::alertcount;

use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(value_of is_excluded is_empty);

sub custom_result_output {
    my ($self, %options) = @_;
    return "Log count: " . $self->{result_values}->{count};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alerts', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 } }    ];

    $self->{maps_counters}->{alerts} = [
        { label => 'total-alerts', nlabel => 'alerts.total.count', display_ok => 1, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%d', min => 0}
                ]
            }
        },
        { label => 'unknown-alerts', nlabel => 'alerts.unknown.count', set => {
                key_values => [ { name => 'unknown', no_value => -1 } ],
                output_template => 'unknown: %s',
                perfdatas => [
                    { template => '%d', min => 0}
                ]
            }
        },
        { label => 'ok-alerts', nlabel => 'alerts.ok.count', set => {
                key_values => [ { name => 'ok', no_value => -1 } ],
                output_template => 'ok: %s',
                perfdatas => [
                    { template => '%d', min => 0}
                ]
            }
        },
        { label => 'warn-alerts', nlabel => 'alerts.warn.count', set => {
                key_values => [ { name => 'warn', no_value => -1 } ],
                output_template => 'warn: %s',
                perfdatas => [
                    { template => '%d', min => 0}
                ]
            }
        },
        { label => 'error-alerts', nlabel => 'alerts.error.count', set => {
                key_values => [ { name => 'error', no_value => -1 } ],
                output_template => 'error: %s',
                perfdatas => [
                    { template => '%d', min => 0}
                ]
            }
        },
        { label => 'critical-alerts', nlabel => 'alerts.critical.count', set => {
                key_values => [ { name => 'critical', no_value => -1 } ],
                output_template => 'critical: %s',
                perfdatas => [
                    { template => '%d', min => 0}
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'accepted-statuses:s' => { name => 'accepted_statuses', default => 'unknown,ok,warn,error,critical' },
        'include-name:s'      => { name => 'include_name', default => '' },
        'exclude-name:s'      => { name => 'exclude_name', default => '' },
        'include-message:s'   => { name => 'include_message', default => '' },
        'exclude-message:s'   => { name => 'exclude_message', default => '' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # only the statuses listed here are accepted by the API
    my @valid_statuses = ('unknown', 'ok', 'warn', 'error', 'critical');
    # this array will contained the statuses the user has specified
    my @accepted_statuses = ();
    # set counters to 0 for status that are accepted, -1 if not (will not appear in metrics)
    my %data = (total => 0);
    foreach (@valid_statuses) {
        if ($self->{option_results}->{accepted_statuses} =~ $_) {
            $data{$_} = 0;
            # this status will be asked to the API
            push @accepted_statuses, $_;
        } else {
            # the counter for this status will be ignored
            $data{$_} = -1;
        }
    }

    my $all_alerts = $options{custom}->get_alert_events(accepted_statuses => \@accepted_statuses );

    for my $alert (@$all_alerts) {
        next unless $alert->{status};
        my $alert_message = $alert->{message} // '';

        next if is_excluded(
            $alert_message,
            $self->{option_results}->{include_message},
            $self->{option_results}->{exclude_message},
            output => $self->{output});
        my $alert_name = value_of($alert, '->{attributes}->{"alert_rule.name"}', '');
        next if is_excluded(
            $alert_name,
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name},
            output => $self->{output});

        my $alert_status = $alert->{status};
        $self->{output}->add_option_msg(long_msg => "Alert " . $alert_name . " has status " . $alert_status . " and message: " . $alert_message );
        $data{$alert_status} += 1;
        $data{total} += 1;
    }
    $self->{alerts} = \%data;
}

1;

__END__

=head1 MODE

Monitor the number of alerts per status.

=over 8

=item B<--accepted-statuses>

Parameter for the API request. Must be a comma separated array of valid statuses.
Valid statuses are: C<'unknown', 'ok', 'warn', 'error', 'critical'>
Example: C<--accepted-statuses='error,critical'>.
Default: C<'unknown,ok,warn,error,critical'> (all statuses).

=item B<--include-name>

Filter by including only the alerts whose name matches the regular expression provided after this parameter.

=item B<--exclude-name>

Filter by excluding only the alerts whose name matches the regular expression provided after this parameter.

=item B<--include-message>

Filter by including only the alerts whose message matches the regular expression provided after this parameter.

=item B<--exclude-message>

Filter by excluding only the alerts whose message matches the regular expression provided after this parameter.

=item B<--warning-critical-alerts>

Threshold.

=item B<--critical-critical-alerts>

Threshold.

=item B<--warning-error-alerts>

Threshold.

=item B<--critical-error-alerts>

Threshold.

=item B<--warning-ok-alerts>

Threshold.

=item B<--critical-ok-alerts>

Threshold.

=item B<--warning-total-alerts>

Threshold.

=item B<--critical-total-alerts>

Threshold.

=item B<--warning-unknown-alerts>

Threshold.

=item B<--critical-unknown-alerts>

Threshold.

=item B<--warning-warn-alerts>

Threshold.

=item B<--critical-warn-alerts>

Threshold.

=back

=cut
