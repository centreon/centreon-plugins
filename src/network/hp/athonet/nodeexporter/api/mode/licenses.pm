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

package network::hp::athonet::nodeexporter::api::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "License '%s' ",
        $options{instance_value}->{targetType}
    );
}

sub prefix_global_registration_output {
    my ($self, %options) = @_;

    return 'Number of network function registrations ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'licenses', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All licenses are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'licenses-detected', display_ok => 0, nlabel => 'licenses.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'licenses-valid', display_ok => 0, nlabel => 'licenses.valid.count', display_ok => 0, set => {
                key_values => [ { name => 'valid' }, { name => 'detected' } ],
                output_template => 'valid: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        },
        { label => 'licenses-invalid', display_ok => 0, nlabel => 'licenses.invalid.count', display_ok => 0, set => {
                key_values => [ { name => 'invalid' }, { name => 'detected' } ],
                output_template => 'invalid: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{licenses} = [
        { label => 'license-status', type => 2, critical_default => '%{status} =~ /invalid/i', set => {
                key_values => [ { name => 'status' }, { name => 'targetType' } ],
                output_template => 'status: %s',
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
        'filter-target-type:s' => { name => 'filter_target_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_license_status = { 1 => 'valid', 0 => 'invalid' };
    my $licenses = $options{custom}->query(queries => ['license_status']);

    $self->{global} = { detected => 0, valid => 0, invalid => 0 };
    $self->{licenses} = {};
    foreach my $license (@$licenses) {
        next if (defined($self->{option_results}->{filter_target_type}) && $self->{option_results}->{filter_target_type} ne '' &&
            $license->{metric}->{target_type} !~ /$self->{option_results}->{filter_target_type}/);

        $self->{licenses}->{ $license->{metric}->{target_type} } = {
            targetType => $license->{metric}->{target_type},
            status => $map_license_status->{ $license->{value}->[1] }
        };
        $self->{global}->{detected}++;
        $self->{global}->{lc($map_license_status->{ $license->{value}->[1] })}++;
    }
}

1;

__END__

=head1 MODE

Check licenses.

=over 8

=item B<--filter-target-type>

Filter licenses by target type.

=item B<--unknown-license-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{targetType}

=item B<--warning-license-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{targetType}

=item B<--critical-license-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /invalid/i').
You can use the following variables: %{status}, %{targetType}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'licenses-detected', 'licenses-valid', 'licenses-invalid'.

=back

=cut
