#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::hp::athonet::nodeexporter::api::mode::chargingfunction;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_sbi_registration_output {
    my ($self, %options) = @_;

    return "SBI registration network function ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'sbi_registration', type => 0, cb_prefix_output => 'prefix_sbi_registration_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sessions-active-charging', nlabel => 'chf.sessions.active.charging.count', set => {
                key_values => [ { name => 'chf_active_charging_sessions' } ],
                output_template => 'active converged charging sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sbi_registration} = [
        { label => 'sbi-nf-registration-status', type => 2, critical_default => '%{status} =~ /suspended/i', set => {
                key_values => [ { name => 'status' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'sbi-nf-registration-detected', display_ok => 0, nlabel => 'sbi.nf.registration.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'sbi-nf-registration-registered', display_ok => 0, nlabel => 'sbi.nf.registration.registered.count', display_ok => 0, set => {
                key_values => [ { name => 'registered' }, { name => 'detected' } ],
                output_template => 'registered: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        },
        { label => 'sbi-nf-registration-suspended', display_ok => 0, nlabel => 'sbi.nf.registration.suspended.count', display_ok => 0, set => {
                key_values => [ { name => 'suspended' }, { name => 'detected' } ],
                output_template => 'suspended: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $response = $options{custom}->query(queries => ['chf_active_charging_sessions']);
    $self->{global}->{chf_active_charging_sessions} = $response->[0]->{value}->[1];

    my $map_registration_status = { 1 => 'registered', 0 => 'suspended' };

    my $registration_infos = $options{custom}->query(queries => ['sbi_nrf_registration_status{target_type="chf"}']);
    $self->{sbi_registration} = { detected => 0, registered => 0, suspended => 0 };
    foreach my $info (@$registration_infos) {
        $self->{sbi_registration}->{status} = $map_registration_status->{ $info->{value}->[1] };
        $self->{sbi_registration}->{detected}++;
        $self->{sbi_registration}->{lc($map_registration_status->{ $info->{value}->[1] })}++;
    }
}

1;

__END__

=head1 MODE

Check charging function.

=over 8

=item B<--unknown-sbi-nf-registration-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}

=item B<--warning-sbi-nf-registration-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-sbi-nf-registration-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /suspended/i').
You can use the following variables: %{status}

=item B<--warning-sbi-nf-registration-detected>

Threshold.

=item B<--critical-sbi-nf-registration-detected>

Threshold.

=item B<--warning-sbi-nf-registration-registered>

Threshold.

=item B<--critical-sbi-nf-registration-registered>

Threshold.

=item B<--warning-sbi-nf-registration-suspended>

Threshold.

=item B<--critical-sbi-nf-registration-suspended>

Threshold.

=item B<--warning-sessions-active-charging>

Threshold.

=item B<--critical-sessions-active-charging>

Threshold.

=cut
