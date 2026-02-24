#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package cloud::cisco::webex::restapi::mode::devicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'devices',
            type             => 1,
            cb_prefix_output => 'prefix_output',
            skipped_code     => { -10 => 1 },
            message_multiple => 'All devices are ok'
        }
    ];

    $self->{maps_counters}->{devices} = [
        {
            label            => 'status',
            type             => 2,
            unknown_default  => '',
            critical_default => '%{error_codes} =~ /accountmissing|softwareupgradekeepsfailing|wifiradioquality/i',
            warning_default  =>
                '%{lifecycle} =~ /END_OF_SALE|UPCOMING_END_OF_SUPPORT/i || %{connection_status} =~ /disconnected/i || %{error_codes} =~ /upcomingendofsupport|networkquality|currentnetworkquality/i',
            set              =>
                {
                    key_values                     => [
                        { name => 'display_name' },
                        { name => 'product' },
                        { name => 'ip' },
                        { name => 'type' },
                        { name => 'serial' },
                        { name => 'error_codes' },
                        { name => 'planned_maintenance' },
                        { name => 'lifecycle' },
                        { name => 'connection_status' },

                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    my $pref = "device '" . $options{instance_value}->{display_name} . "'";

    if (defined($options{instance_value}->{ip}) && $options{instance_value}->{ip}) {
        $pref = $pref . " - $options{instance_value}->{ip}";
    }

    if (defined($options{instance_value}->{product}) && $options{instance_value}->{product}) {
        $pref = $pref . ", $options{instance_value}->{product}";
    }

    if (defined($options{instance_value}->{type}) && $options{instance_value}->{type}) {
        $pref = $pref . " ($options{instance_value}->{type})";
    }

    if (defined($options{instance_value}->{serial}) && $options{instance_value}->{serial}) {
        $pref = $pref . " - $options{instance_value}->{serial}";
    }

    $pref = $pref . " - ";

    return $pref;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $error = defined($self->{result_values}->{error_codes}) ? $self->{result_values}->{error_codes} : 'NA';

    if (defined($self->{result_values}->{error_codes}) && $self->{result_values}->{error_codes}) {
        return "Error codes: $error - Connection status: $self->{result_values}->{connection_status} - Planed maintenance: $self->{result_values}->{planned_maintenance} - Lifecycle: $self->{result_values}->{lifecycle}";
    }

    return "Connection status: $self->{result_values}->{connection_status} - Planed maintenance: $self->{result_values}->{planned_maintenance} - Lifecycle: $self->{result_values}->{lifecycle}";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            'device-id:s'     => { name => 'device_id' },
            'workspace-id:s'  => { name => 'workspace_id' },
            'person-id:s'     => { name => 'person_id' },
            'resource-type:s' => { name => 'resource_type', default => 'workspace' },
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{resource_type} !~ /^workspace|person/) {
        $self->{output}->add_option_msg(short_msg => 'Unknown resource type. Must be "workspace" or "person"');
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{device_id}) && $self->{option_results}->{resource_type} eq 'workspace'
        && (!defined($self->{option_results}->{workspace_id}) || $self->{option_results}->{workspace_id} eq '')) {
        $self->{output}->add_option_msg(short_msg =>
            'Need to specify --workspace-id option when using --resource-type "workspace"');
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{device_id}) && $self->{option_results}->{resource_type} eq 'person'
        && (!defined($self->{option_results}->{person_id}) || $self->{option_results}->{person_id} eq '')) {
        $self->{output}->add_option_msg(short_msg =>
            'Need to specify --person-id option when using --resource-type "person"');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{device_id}) && $self->{option_results}->{device_id} ne '') {
        $self->{devices} = $options{custom}->get_device();
    } else {
        my $devices = $options{custom}->get_devices();

        foreach my $device (@{$devices}) {
            $self->{devices}->{$device->{id}} = $device;
        }
    }

    if (scalar(keys %{$self->{devices}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No device found with this --device-id.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check device status.

=over 8

=item B<--device-id>

Filter device by device-id.

=item B<--workspace-id>

Filter devices by workspace id.

=item B<--unknown-status>

Set unknown threshold for status. (Default: '')
Can used special variables like: %{error_codes}, %{connection_status}, %{planned_maintenance}, %{lifecycle}

=item B<--warning--status>

Set warning threshold for status (Default: '%{lifecycle} =~ /END_OF_SALE|UPCOMING_END_OF_SUPPORT/i || %{connection_status} =~ /disconnected/i || %{error_codes} =~ /upcomingendofsupport|networkquality|currentnetworkquality/i')
Can used special variables like: %{error_codes}, %{connection_status}, %{planned_maintenance}, %{lifecycle}

=item B<--critical-status>

Set critical threshold for status (Default: '%{error_codes} =~ /accountmissing|softwareupgradekeepsfailing|wifiradioquality|temperaturecheck/i').
Can used special variables like: %{error_codes}, %{connection_status}, %{planned_maintenance}, %{lifecycle}

=back

=cut