#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::vxm::restapi::mode::chassis;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_chassis_output {
    my ($self, %options) = @_;

    return "chassis '" . $options{instance} . "' ";
}

sub chassis_long_output {
    my ($self, %options) = @_;

    return "checking chassis '" . $options{instance} . "'";
}

sub prefix_psu_output {
    my ($self, %options) = @_;

    return "power supply '" . $options{instance} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of chassis ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'chassis', type => 3, cb_prefix_output => 'prefix_chassis_output', cb_long_output => 'chassis_long_output', indent_long_output => '    ', message_multiple => 'All chassis are ok', 
            group => [
                { name => 'health', type => 0, skipped_code => { -10 => 1 } },
                { name => 'psu', type => 1, display_long => 1, cb_prefix_output => 'prefix_psu_output', message_multiple => 'All power supplies are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'chassis-detected', nlabel => 'chassis.detected.count', set => {
                key_values => [ { name => 'num_chassis' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'chassis-unhealthy', nlabel => 'chassis.unhealthy.count', set => {
                key_values => [ { name => 'unhealthy' } ],
                output_template => 'unhealthy: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{health} = [
        {
            label => 'chassis-status',
            type => 2,
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /critical|error/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'chassisSn' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{psu} = [
        {
            label => 'psu-status',
            type => 2,
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /critical|error/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'chassisSn' }, { name => 'psuName' } ],
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
        'filter-chassis-sn:s' => { name => 'filter_chassis_sn' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request(endpoint => '/chassis');

    $self->{global} = { num_chassis => 0, unhealthy => 0 };
    $self->{chassis} = {};
    foreach my $entry (@$results) {
        next if (defined($self->{option_results}->{filter_chassis_sn}) && $self->{option_results}->{filter_chassis_sn} ne ''
            && $entry->{sn} !~ /$self->{option_results}->{filter_chassis_sn}/);

        $self->{global}->{num_chassis}++;
        $self->{global}->{unhealthy}++ if ($entry->{health} !~ /^Healthy$/i);

        $self->{chassis}->{ $entry->{sn} } = {
            health => { status => $entry->{health}, chassisSn => $entry->{sn} },
            psu => {}
        };

        foreach my $psu (@{$entry->{power_supplies}}) {
            $self->{chassis}->{ $entry->{sn} }->{psu}->{ $psu->{name} } = {
                chassisSn => $entry->{sn},
                psuName => $psu->{name},
                status => $psu->{health}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check chassis.

=over 8

=item B<--filter-chassis-sn>

Filter clusters by serial number (can be a regexp).

=item B<--unknown-chassis-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{chassisSn}

=item B<--warning-chassis-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /warning/i').
You can use the following variables: %{status}, %{chassisSn}

=item B<--critical-chassis-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /critical|error/i').
You can use the following variables: %{status}, %{chassisSn}

=item B<--unknown-psu-status>

Set unknown threshold for power supply status.
You can use the following variables: %{status}, %{chassisSn}, %{psuName}

=item B<--warning-psu-status>

Set warning threshold for power supply status (default: '%{status} =~ /warning/i').
You can use the following variables: %{status}, %{chassisSn}, %{psuName}

=item B<--critical-psu-status>

Set critical threshold for power supply status (default: '%{status} =~ /critical|error/i').
You can use the following variables: %{status}, %{chassisSn}, %{psuName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'chassis-detected', 'chassis-unhealthy'.

=back

=cut
