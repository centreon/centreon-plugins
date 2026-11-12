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

package apps::backup::veeam::vbr::restapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc qw/change_seconds value_of/;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_license_instances_output {
    my ($self, %options) = @_;

    return sprintf(
        'instances total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{instances_total},
        $self->{result_values}->{instances_used},
        $self->{result_values}->{instances_prct_used},
        $self->{result_values}->{instances_free},
        $self->{result_values}->{instances_prct_free}
    );
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "License '%s' [type: %s] [edition: %s] ",
        $self->{global}->{to},
        $self->{global}->{type},
        $self->{global}->{edition}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_license_output', skipped_code => { NO_VALUE() => 1 } }
    ];

    my @instances_values = map { { name => $_ } } qw/instances_used instances_free instances_prct_used instances_prct_free instances_total/;
    $self->{maps_counters}->{global} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{status} =~ /expired|invalid/i', set => {
                key_values => [ { name => 'status' }, { name => 'to' }, { name => 'type' }, { name => 'edition' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'expires', nlabel => 'license.expires.days', set => {
                key_values => [ { name => 'expires_days' }, { name => 'expires_human' } ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                perfdatas => [
                    { template => '%d', unit => 'd', min => 0 }
                ]
            }
        },
        { label => 'license-instances-usage', nlabel => 'license.instances.usage.count', set => {
                key_values => [ @instances_values ],
                closure_custom_output => $self->can('custom_license_instances_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'instances_total' }
                ]
            }
        },
        { label => 'license-instances-free', display_ok => 0, nlabel => 'license.instances.free.count', set => {
                key_values => [ { name => 'instances_free' }, grep { $_->{name} ne 'instances_free' } @instances_values ],
                closure_custom_output => $self->can('custom_license_instances_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'instances_total' }
                ]
            }
        },
        { label => 'license-instances-usage-prct', display_ok => 0, nlabel => 'license.instances.usage.percentage', set => {
                key_values => [ { name => 'instances_prct_used' }, grep { $_->{name} ne 'instances_prct_used' } @instances_values ],
                closure_custom_output => $self->can('custom_license_instances_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $license = $options{custom}->get_license();

    $self->{global} = {
        to => value_of($license, '->{licensedTo}', '-'),
        type => value_of($license, '->{type}', '-'),
        edition => value_of($license, '->{edition}', '-'),
        status => value_of($license, '->{status}', 'unknown')
    };

    # The expiration date is documented at the root level but some servers
    # return it in the instances summary
    my $expiration_date = value_of($license, '->{expirationDate}', value_of($license, '->{instanceLicenseSummary}->{expirationDate}'));
    if ($expiration_date =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(?:\.\d+)?(Z|[+-]\d{2}:?\d{2})?$/) {
        my $dt = DateTime->new(
            year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6,
            time_zone => !defined($7) || $7 eq 'Z' ? 'UTC' : $7 =~ s/://r
        );
        my $expires_seconds = $dt->epoch() - time();
        $expires_seconds = 0 if $expires_seconds < 0;
        $self->{global}->{expires_days} = int($expires_seconds / 86400);
        $self->{global}->{expires_human} = change_seconds(value => $expires_seconds) || '0s';
    }

    my $licensed = value_of($license, '->{instanceLicenseSummary}->{licensedInstancesNumber}', 0);
    if ($licensed > 0) {
        my $used = value_of($license, '->{instanceLicenseSummary}->{usedInstancesNumber}', 0);
        $self->{global}->{instances_total} = $licensed;
        $self->{global}->{instances_used} = $used;
        $self->{global}->{instances_free} = $licensed - $used > 0 ? $licensed - $used : 0;
        $self->{global}->{instances_prct_used} = $used * 100 / $licensed;
        $self->{global}->{instances_prct_free} = 100 - $self->{global}->{instances_prct_used};
    }
}

1;

__END__

=head1 MODE

Check the installed license.

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{to}, %{type}, %{edition}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /expired|invalid/i').
You can use the following variables: %{status}, %{to}, %{type}, %{edition}

=item B<--warning-expires>

Threshold in days.

=item B<--critical-expires>

Threshold in days.

=item B<--warning-license-instances-usage>

Threshold.

=item B<--critical-license-instances-usage>

Threshold.

=item B<--warning-license-instances-free>

Threshold.

=item B<--critical-license-instances-free>

Threshold.

=item B<--warning-license-instances-usage-prct>

Threshold in percentage.

=item B<--critical-license-instances-usage-prct>

Threshold in percentage.

=back

=cut
