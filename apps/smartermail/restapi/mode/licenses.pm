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
# Authors : Roman Morandell - ivertix
#

package apps::smartermail::restapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_upgrade_protection_status_output {
    my ($self, %options) = @_;

    return 'upgrade protection status is ' . $self->{result_values}->{upgrade_protection_status};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'upgrade-protection-status', type => 2, critical_default => '%{upgrade_protection_status} =~ /expired/', set => {
                key_values => [ { name => 'upgrade_protection_status' } ],
                closure_custom_perfdata => sub { return 0; },
                closure_custom_output => $self->can('custom_upgrade_protection_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'upgrade-protection-expires-days', nlabel => 'license.upgrade.protection.expires.days.count', set => {
                key_values      => [ { name => 'upgrade_protection_expires_days' } ],
                output_template => 'upgrade protection expires in %d days',
                perfdatas       => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/settings/sysadmin/license-notifications');

    $self->{global} = {
        upgrade_protection_expires_days => $result->{daysUntilUpgradeProtectionExpires},
        upgrade_protection_status => $result->{isUpgradeProtectionExpired} =~ /True|1/i ? 'expired' : 'licensed'
    };
}


1;

__END__

=head1 MODE

Check licenses.

=over 8

=item B<--unknown-upgrade-protection-status>

Set unknown threshold for status.
Can used special variables like: %{upgrade_protection_status}

=item B<--warning-upgrade-protection-status>

Set warning threshold for status.
Can used special variables like: %{upgrade_protection_status}

=item B<--critical-upgrade-protection-status>

Set critical threshold for status (Default: '%{upgrade_protection_status} =~ /expired/').
Can used special variables like: %{upgrade_protection_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'upgrade-protection-expires-days'.

=back

=cut
