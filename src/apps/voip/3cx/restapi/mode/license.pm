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

package apps::voip::3cx::restapi::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Date::Parse;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc qw/is_excluded int_to_bool exprintf/;

sub custom_license_status_output {
    my ($self, %options) = @_;

    my $label;

    if ( $self->{result_values}->{expires_in} < 0 ) {
        $label = sprintf('License expired %d day(s) ago', - $self->{result_values}->{expires_in});
    } elsif (! $self->{result_values}->{license_active} ) {
        $label = 'License inactive'
    } elsif (! $self->{result_values}->{activated}) {
        $label = 'License activation error';
    } else {
        $label = exprintf('License active (expires on %{expires_date})', $self->{result_values});
    }

    return $label;
}

sub custom_support_status_output {
    my ($self, %options) = @_;

    my $label;

    if ($self->{result_values}->{support}) {
        $label = exprintf('Support enabled (expires on %{maintenance_expires_date})', $self->{result_values});
    } else {
        if ($self->{result_values}->{maintenance_expires_in} < 0) {
            $label = sprintf('Support expired %d day(s) ago', - $self->{result_values}->{maintenance_expires_in});
        } else {
            $label = 'Support disabled';
        }
    }

    return $label;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'license', type => COUNTER_KIND_TEXT, critical_default => '%{activated} !~ /true/ || %{license_active} !~ /true/',
                warning_default => '%{expires_in} < 10',  set => {
                key_values => [ { name => 'activated' }, { name => 'license_active' }, { name => 'support' }, { name => 'expires_in' }, { name => 'expires_date' },
                                { name => 'maintenance_expires_in' }, { name => 'maintenance_expires_date' } ],
                closure_custom_output => $self->can('custom_license_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'support', type => COUNTER_KIND_TEXT, warning_default => '%{support} !~ /true/', set => {
                key_values => [ { name => 'activated' }, { name => 'license_active' }, { name => 'support' }, { name => 'expires_in' }, { name => 'expires_date' },
                                { name => 'maintenance_expires_in' }, { name => 'maintenance_expires_date' } ],
                closure_custom_output => $self->can('custom_support_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $system = $options{custom}->api_system_status();

    my $expiration_date = $system->{ExpirationDate} // '';
    my $maintenance_expires_at = $system->{MaintenanceExpiresAt} // '';

    my $expires_in = str2time($expiration_date);
    $expires_in = defined $expires_in ? int (($expires_in - time()) / 86400) : -1;

    my $maintenance_expires_in = str2time($maintenance_expires_at);
    $maintenance_expires_in = defined $maintenance_expires_in ? (($maintenance_expires_in - time()) / 86400) : -1;

    $self->{global} = {
        activated => int_to_bool($system->{Activated}),
        license_active => int_to_bool($system->{LicenseActive}),
        support => int_to_bool($system->{Support}),
        expires_in => $expires_in,
        expires_date => $expiration_date,
        maintenance_expires_in => $maintenance_expires_in,
        maintenance_expires_date => $maintenance_expires_at,
    };
}

1;

__END__

=head1 MODE

Check 3CX system license and support status (v20+).

=over 8

=item B<--warning-license>

Set warning condition for license status.
Default: '%{expires_in} < 10' (license expires within 10 days).
Variables available: C<activated>, C<license_active>, C<expires_in>, C<expires_date>

=item B<--critical-license>

Set critical condition for license status.
Default: '%{activated} !~ /true/ || %{license_active} !~ /true/' (license not activated or not active).
Variables available: C<activated>, C<license_active>, C<expires_in> (in days), C<expires_date>

=item B<--warning-support>

Set warning condition for support status.
Default: '%{support} !~ /true/' (support disabled).
Variables available: C<support>, C<maintenance_expires_in> (in days), C<maintenance_expires_date>

=item B<--critical-support>

Set critical condition for support status.
Variables available: C<support>, C<maintenance_expires_in>, C<maintenance_expires_date>

=back

=cut
