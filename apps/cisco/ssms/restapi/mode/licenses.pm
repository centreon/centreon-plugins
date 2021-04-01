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

package apps::cisco::ssms::restapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: '%s'",
        $self->{result_values}->{status}
    );
}

sub custom_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
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

sub prefix_license_output {
    my ($self, %options) = @_;

    return "license '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'accounts', type => 3, cb_prefix_output => 'prefix_account_output', cb_long_output => 'account_long_output', indent_long_output => '    ', message_multiple => 'All accounts are ok',
            group => [
                { name => 'licenses', display_long => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'licenses are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{licenses} = [
        { label => 'license-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'usage', nlabel => 'licenses.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'licenses.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'licenses.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'account:s@'                => { name => 'account' },
        'filter-license-name:s'     => { name => 'filter_license_name' },
        'unknown-license-status:s'  => { name => 'unknown_license_status', default => '' },
        'warning-license-status:s'  => { name => 'warning_license_status', default => '' },
        'critical-license-status:s' => { name => 'critical_license_status', default => '%{status} !~ /in compliance/i' }
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

    $self->change_macros(macros => ['warning_license_status', 'critical_license_status', 'unknown_license_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{accounts} = {};
    foreach my $account (@{$self->{account_names}}) {
        my $results = $options{custom}->get_licenses(
            account => $account
        );

        next if (!defined($results->{licenses}));

        $self->{accounts}->{$account} = {
            display => $account,
            licenses => {}
        };
        foreach (@{$results->{licenses}}) {
            next if (defined($self->{option_results}->{filter_license_name}) && $self->{option_results}->{filter_license_name} ne '' &&
                $_->{license} !~ /$self->{option_results}->{filter_license_name}/);

            $self->{accounts}->{$account}->{licenses}->{ $_->{license} } = {
                display => $_->{license},
                status => $_->{status},
                used => $_->{inUse},
                free => $_->{available},
                total => $_->{quantity},
                prct_used => $_->{inUse} * 100 / $_->{quantity},
                prct_free => $_->{available} * 100 / $_->{quantity}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check licenses.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--account>

Check account name (Required. Multiple option).

=item B<--filter-license-name>

Filter license name (can be a regexp).

=item B<--unknown-license-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-license-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-license-status>

Set critical threshold for status (Default: '%{status} !~ /in compliance/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
