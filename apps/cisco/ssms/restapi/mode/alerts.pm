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

package apps::cisco::ssms::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_alert_output {
    my ($self, %options) = @_;

    return sprintf(
        '[message type: %s] [severity: %s] [source: %s]',
        $self->{result_values}->{message_type},
        $self->{result_values}->{severity},
        $self->{result_values}->{source} ne '' ? $self->{result_values}->{source} : '-'
    );
}

sub account_long_output {
    my ($self, %options) = @_;

    return "checking account '" . $options{instance_value}->{display} . "'";
}

sub prefix_account_output {
    my ($self, %options) = @_;

    return "account '" . $options{instance_value}->{display} . "' ";
}

sub prefix_alerts_global_output {
    my ($self, %options) = @_;

    return 'alerts ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'accounts', type => 3, cb_prefix_output => 'prefix_account_output', cb_long_output => 'account_long_output', indent_long_output => '    ', message_multiple => 'All accounts are ok',
            group => [
                { name => 'alerts_global', type => 0, cb_prefix_output => 'prefix_alerts_global_output' },
                { name => 'alerts', type => 1, display_short => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{alerts_global} = [
        { label => 'alerts-minor', nlabel => 'account.alerts.minor.count', set => {
                key_values => [ { name => 'minor' } ],
                output_template => 'minor: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'alerts-major', nlabel => 'account.alerts.major.count', set => {
                key_values => [ { name => 'major' } ],
                output_template => 'major: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{alerts} = [
        { label => 'alert-status', threshold => 0, set => {
                key_values => [ { name => 'severity' }, { name => 'message_type' }, { name => 'source' } ],
                closure_custom_output => $self->can('custom_alert_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => sub { return 'ok'; }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'account:s@'            => { name => 'account' },
        'filter-message-type:s' => { name => 'filter_message_type' },
        'display-alerts'        => { name => 'display_alerts' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{account_names} = [];
    if (defined($self->{option_results}->{account})) {
        foreach my $account (@{$self->{option_results}->{account}}) {
            push @{$self->{account_names}}, $account if ($account ne '');
        }
    }
    if (scalar(@{$self->{account_names}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'need to specify --account option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{accounts} = {};
    foreach my $account (@{$self->{account_names}}) {
        my $results = $options{custom}->get_alerts(
            account => $account
        );

        next if (!defined($results->{alerts}));

        $self->{accounts}->{$account} = {
            display => $account,
            alerts_global => { minor => 0, major => 0 },
            alerts => {}
        };
        my $i = 0;
        foreach (@{$results->{alerts}}) {
            next if (defined($self->{option_results}->{filter_message_type}) && $self->{option_results}->{filter_message_type} ne '' &&
                $_->{messageType} !~ /$self->{option_results}->{filter_message_type}/);

            $self->{accounts}->{$account}->{alerts_global}->{ lc($_->{severity}) }++;

            next if (!defined($self->{option_results}->{display_alerts}));

            $self->{accounts}->{$account}->{alerts}->{$i} = {
                message_type => $_->{messageType},
                severity => lc($_->{severity}),
                source => $_->{source}
            };

            $i++;
        }
    }
}

1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='minor'

=item B<--account>

Check account name (Required. Multiple option).

=item B<--filter-message-type>

Filter alerts by message type (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'alerts-minor', 'alerts-major'.

=back

=cut
