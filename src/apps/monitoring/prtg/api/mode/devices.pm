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

package apps::monitoring::prtg::api::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{status}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of devices ';
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return sprintf(
        "device '%s' ",
        $options{instance_value}->{deviceName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'devices', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok' }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'devices-detected', display_ok => 0, nlabel => 'devices.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{devices} = [
        {
            label => 'device-status',
            type => COUNTER_KIND_TEXT,
            unknown_default  => '%{status} =~ /unknown|unusual|noProbe|pausedbyLicense/',
            warning_default  => '%{status} =~ /warning/',
            critical_default => '%{status} =~ /down|critical/',
            set => {
                key_values => [ { name => 'status' }, { name => 'deviceName' } ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'include-device-id:s'   => { name => 'include_device_id',  default => '' },
        'exclude-device-id:s'   => { name => 'exclude_device_id',  default => '' },
        'include-device-name:s' => { name => 'include_device_name',  default => '' },
        'exclude-device-name:s' => { name => 'exclude_device_name',  default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $devices = $options{custom}->get_devices();

    $self->{global} = { detected => 0 };
    $self->{devices} = {};
    foreach my $dev (values %$devices) {
        next if is_excluded($dev->{name}, $self->{option_results}->{include_device_name}, $self->{option_results}->{exclude_device_name});
        next if is_excluded($dev->{id}, $self->{option_results}->{include_device_id}, $self->{option_results}->{exclude_device_id});

        $self->{devices}->{ $dev->{id} } = {
            deviceName => $dev->{name},
            status => $dev->{status}
        };

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check devices status.

=over 8

=item B<--include-device-name>

Include device names (regexp).

=item B<--exclude-device-name>

Exclude device names (regexp).

=item B<--include-device-id>

Include device IDs (regexp).

=item B<--exclude-device-id>

Exclude device IDs (regexp).

=item B<--warning-devices-detected>

Threshold.

=item B<--critical-devices-detected>

Threshold.

=item B<--unknown-device-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /unknown|unusual|noProbe|pausedbyLicense/').
You can use the following variables: %{deviceName}, %{status}

=item B<--warning-device-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /warning/').
You can use the following variables: %{deviceName}, %{status}

=item B<--critical-device-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /down|critical/').
You can use the following variables: %{deviceName}, %{status}

=back

=cut