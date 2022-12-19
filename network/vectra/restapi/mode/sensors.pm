#
# Copyright 2022 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package network::vectra::restapi::mode::sensors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub sensor_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sensor '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_sensor_output {
    my ($self, %options) = @_;

    return sprintf(
        "sensor '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'sensors', type => 3, cb_prefix_output => 'prefix_sensor_output', cb_long_output => 'sensor_long_output', indent_long_output => '    ', message_multiple => 'All sensors are ok',
            group => [
                { name => 'global', type => 0 },
                { name => 'boards', display_long => 1, cb_prefix_output => 'prefix_board_output',
                  message_multiple => 'all boards are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'psu', display_long => 1, cb_prefix_output => 'prefix_psu_output',
                  message_multiple => 'all power supplies are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'drives', display_long => 1, cb_prefix_output => 'prefix_drive_output',
                  message_multiple => 'all drives are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sensor-status', type => 2, critical_default => '%{status} !~ /^paired/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'trafficdrop-status', type => 2, warning_default => '%{trafficDropStatus} =~ /warning|unknown|skip/i', set => {
                key_values => [ { name => 'trafficDropStatus' }, { name => 'name' } ],
                output_template => 'traffic drop status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

     $options{options}->add_options(arguments => {
        'filter-sensor-name:s' => { name => 'filter_sensor_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/health/sensors');

    $self->{sensors} = {};
    foreach (@{$result->{sensors}}) {
        next if (defined($self->{option_results}->{filter_sensor_name}) && $self->{option_results}->{filter_sensor_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_sensor_name}/);

        $self->{sensors}->{ $_->{luid} } = {
            name => $_->{name},
            global => { name => $_->{name}, status => lc($_->{status}) }
        };
    }

    $result = $options{custom}->request_api(endpoint => '/health/trafficdrop');
    foreach (@{$result->{trafficdrop}->{sensors}}) {
        next if (!defined($self->{sensors}->{ $_->{luid} }));

        $self->{sensors}->{ $_->{luid} }->{global}->{trafficDropStatus} = lc($_->{status});
    }
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--filter-sensor-name>

Filter sensors by name (can be a regexp).

=item B<--unknown-sensor-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-sensor-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-sensor-status>

Set critical threshold for status (Default: '%{status} !~ /^paired/i').
Can used special variables like: %{status}, %{name}

=item B<--unknown-trafficdrop-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-trafficdrop-status>

Set warning threshold for status  (Default: '%{trafficDropStatus} =~ /warning|unknown|skip/i').
Can used special variables like: %{status}, %{name}

=item B<--critical-trafficdrop-status>

Set critical threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds. Can be:
'memory-usage', 'memory-usage-free', 'memory-usage-prct'

=back

=cut
