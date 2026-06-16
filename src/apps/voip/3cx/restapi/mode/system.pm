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

package apps::voip::3cx::restapi::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc qw/is_excluded int_to_bool/;
use List::Util qw/any/;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { name => 'service', type => COUNTER_TYPE_INSTANCE, prefix_output => "3CX '%{service}' ", message_multiple => 'All services are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'calls-active-usage', nlabel => 'system.calls.active.usage.count', set => {
                key_values => [ { name => 'calls_used' }, { name => 'calls_free' }, { name => 'calls_prct_used' }, { name => 'calls_max' } ],
                output_template => 'active calls usage total: %{calls_max} used: %{calls_used} (%{calls_prct_used|%.2f}%%) free: %{calls_free} (%{calls_prct_used|%.2f}%%)',
                perfdatas => [
                    { template => '%d', min => 0, max => 'calls_max' }
                ]
            }
        },
        { label => 'calls-active-free', nlabel => 'system.calls.active.free.count', display_ok => 0, set => {
                key_values => [ { name => 'calls_free' }, { name => 'calls_used' }, { name => 'calls_prct_used' }, { name => 'calls_max' } ],
                output_template => 'active calls usage total: %{calls_max} used: %{calls_used} (%{calls_prct_used|%.2f}%%) free: %{calls_free} (%{calls_prct_used|%.2f}%%)',
                perfdatas => [
                    { template => '%d', min => 0, max => 'calls_max' }
                ]
            }
        },
        { label => 'calls-active-usage-prct', nlabel => 'system.calls.active.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'calls_prct_used' }, { name => 'calls_free' }, { name => 'calls_used' }, { name => 'calls_max' } ],
                output_template => 'active calls usage total: %{calls_max} used: %{calls_used} (%{calls_prct_used|%.2f}%%) free: %{calls_free} (%{calls_prct_used|%.2f}%%)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 'calls_max' }
                ]
            }
        },
        { label => 'extensions-registered', nlabel => 'system.extensions.registered.count', set => {
                key_values => [ { name => 'extensions_registered' }, { name => 'extensions_total' } ],
                output_template => 'extensions registered: %{extensions_registered}',
                perfdatas => [
                    { label => 'extensions_registered', template => '%s', min => 0, max => 'extensions_total' }
                ]
            }
        },
        { label => 'extensions-usage', nlabel => 'system.extensions.usage.count', set => {
                key_values => [ { name => 'extensions_used' }, { name => 'extensions_free' }, { name => 'extensions_prct_used' }, { name => 'extensions_max' } ],
                output_template => 'extensions usage total: %{extensions_max} used: %{extensions_used} (%{extensions_prct_used|%.2f}%%) free: %{extensions_free} (%{extensions_prct_used|%.2f}%%)',
                perfdatas => [
                    { template => '%d', min => 0, max => 'extensions_max' }
                ]
            }
        },
        { label => 'extensions-free', nlabel => 'system.extensions.free.count', display_ok => 0, set => {
                key_values => [ { name => 'extensions_free' }, { name => 'extensions_used' }, { name => 'extensions_prct_used' }, { name => 'extensions_max' } ],
                output_template => 'extensions usage total: %{extensions_max} used: %{extensions_used} (%{extensions_prct_used|%.2f}%%) free: %{extensions_free} (%{extensions_prct_used|%.2f}%%)',
                perfdatas => [
                    { template => '%d', min => 0, max => 'extensions_max' }
                ]
            }
        },
        { label => 'extensions-usage-prct', nlabel => 'system.extensions.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'extensions_prct_used' }, { name => 'extensions_free' }, { name => 'extensions_used' }, { name => 'extensions_max' } ],
                output_template => 'extensions usage total: %{extensions_max} used: %{extensions_used} (%{extensions_prct_used|%.2f}%%) free: %{extensions_free} (%{extensions_prct_used|%.2f}%%)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }

    ];

    $self->{maps_counters}->{service} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{error} =~ /true/', set => {
                key_values => [ { name => 'error' }, { name => 'service' } ],
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-category:s' =>  { redirect => 'include_category' },
        'include-category:s' => { name => 'include_category', default => '' },
        'exclude-category:s' => { name => 'exclude_category', default => '' },
        'include-service:s' => { name => 'include_service', default => '' },
        'exclude-service:s' => { name => 'exclude_service', default => '' }

    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # v20: GetSingleStatus (Firewall/Phones/Trunks) endpoint no longer exists
    # All health information is now consolidated in SystemStatus
    my $system = $options{custom}->api_system_status();
    my $update = $options{custom}->api_update_checker();

    $self->{service} = {};

    # Trunks: use TrunksRegistered vs TrunksTotal from SystemStatus
    $self->{service}->{HasUnregisteredTrunks} = {
        service => 'HasUnregisteredTrunks',
        error   => int_to_bool($system->{TrunksRegistered} < $system->{TrunksTotal}),
    } unless is_excluded('HasUnregisteredTrunks', $self->{option_results}->{include_service}, $self->{option_results}->{exclude_service}, output => $self->{output});

    # Services health
    $self->{service}->{HasNotRunningServices} = {
        service => 'HasNotRunningServices',
        error   => int_to_bool($system->{HasNotRunningServices}),
    } unless is_excluded('HasNotRunningServices', $self->{option_results}->{include_service}, $self->{option_results}->{exclude_service}, output => $self->{output});

    # System extensions
    $self->{service}->{HasUnregisteredSystemExtensions} = {
        service => 'HasUnregisteredSystemExtensions',
        error   => int_to_bool($system->{HasUnregisteredSystemExtensions}),
    } unless is_excluded('HasUnregisteredSystemExtensions', $self->{option_results}->{include_service}, $self->{option_results}->{exclude_service}, output => $self->{output});

    # Updates
    unless (is_excluded('HasUpdatesAvailable', $self->{option_results}->{include_service}, $self->{option_results}->{exclude_service}, output => $self->{output})) {
        my $updates = any { ! is_excluded( $_->{Category},
                                           $self->{option_results}->{include_category},
                                           $self->{option_results}->{exclude_category},
                                           output => $self->{output} )
                          } @$update;
        $self->{service}->{HasUpdatesAvailable} = {
           service => 'HasUpdatesAvailable',
           error   => int_to_bool($updates)
        };
    }

    $self->{global} = {
        calls_used            => $system->{CallsActive},
        calls_free            => $system->{MaxSimCalls} - $system->{CallsActive},
        calls_max             => $system->{MaxSimCalls},
        calls_prct_used       => $system->{CallsActive} * 100 / $system->{MaxSimCalls},
        extensions_registered => $system->{ExtensionsRegistered},
        extensions_total      => $system->{ExtensionsTotal},
        extensions_used       => $system->{UserExtensions},
        extensions_free       => $system->{MaxUserExtensions} - $system->{UserExtensions},
        extensions_max        => $system->{MaxUserExtensions},
        extensions_prct_used  => $system->{MaxUserExtensions} ? $system->{UserExtensions} * 100 / $system->{MaxUserExtensions} : 100
    };
}

1;

__END__

=head1 MODE

Check system health (3CX v20+)

=over 8

=item B<--include-category>

Filter updates by category (can be a regexp).

=item B<--exclude-category>

Exclude updates by category (can be a regexp).

=item B<--include-service>

Services to include in checks (can be a regexp).
Available services: C<HasUnregisteredTrunks>, HasNotRunningServices>,
C<HasUnregisteredSystemExtensions>, C<HasUpdatesAvailable>.

=item B<--exclude-service>

Services to exclude from checks (can be a regexp).
Available services: C<HasUnregisteredTrunks>, C<HasNotRunningServices>,
C<HasUnregisteredSystemExtensions>, C<HasUpdatesAvailable>.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<error>, C<service>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<error>, C<service>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{error} =~ /true/').
You can use the following variables: C<error>, C<service>
Monitored services: C<HasUnregisteredTrunks>, C<HasNotRunningServices>,
C<HasUnregisteredSystemExtensions>, C<HasUpdatesAvailable>.

=item B<--warning-calls-active-usage>

Threshold for active calls used (count).

=item B<--critical-calls-active-usage>

Threshold for active calls used (count).

=item B<--warning-calls-active-free>

Threshold for active calls free (count).

=item B<--critical-calls-active-free>

Threshold for active calls free (count).

=item B<--warning-calls-active-usage-prct>

Threshold for active calls usage percentage.

=item B<--critical-calls-active-usage-prct>

Threshold for active calls usage percentage.

=item B<--warning-extensions-usage>

Threshold for extensions license usage (count).

=item B<--critical-extensions-usage>

Threshold for extensions license usage (count).

=item B<--warning-extensions-free>

Threshold for extensions free (count).

=item B<--critical-extensions-free>

Threshold for extensions free (count).

=item B<--warning-extensions-registered>

Threshold for extensions registered (count).

=item B<--critical-extensions-registered>

Threshold for extensions registered (count).

=item B<--warning-extensions-usage-prct>

Threshold for extensions license usage percentage.

=item B<--critical-extensions-usage-prct>

Threshold for extensions license usage percentage.

=back

=cut
