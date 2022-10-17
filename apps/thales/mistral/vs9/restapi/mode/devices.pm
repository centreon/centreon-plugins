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

package apps::thales::mistral::vs9::restapi::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_connection_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{time_unit} },
        unit => $self->{instance_mode}->{option_results}->{time_unit},
        instances => $self->{result_values}->{sn},
        value => floor($self->{result_values}->{connection_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_connection_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{connection_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub device_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking device '%s'",
        $options{instance_value}->{sn}
    );
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return sprintf(
        "device '%s' ",
        $options{instance_value}->{sn}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of devices ';
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return sprintf(
        "service '%s' ",
        $options{instance_value}->{service}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'services are ok', display_long => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'devices-detected', display_ok => 0, nlabel => 'devices.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{connection} = [
        {
            label => 'connection-status',
            type => 2,
            unknown_default => '%{connectionStatus} =~ /unknown/i',
            warning_default => '%{connectionStatus} =~ /disconnected/i',
            set => {
                key_values => [ { name => 'connectionStatus' }, { name => 'sn' } ],
                output_template => "connection status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'connection-last-time', nlabel => 'device.connection.last.time', set => {
                key_values      => [ { name => 'connection_seconds' }, { name => 'connection_human' }, { name => 'sn' } ],
                output_template => 'last connection: %s',
                output_use => 'connection_human',
                closure_custom_perfdata => $self->can('custom_connection_perfdata'),
                closure_custom_threshold_check => $self->can('custom_connection_threshold')
            }
        }
    ];

=pod
    $self->{maps_counters}->{dedup} = [
        { label => 'dedup', nlabel => 'appliance.deduplication.ratio.count', set => {
                key_values => [ { name => 'dedup' }, { name => 'name' } ],
                output_template => 'deduplication ratio: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
=cut
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s' => { name => 'filter_id' },
        'filter-sn:s' => { name => 'filter_sn' },
        'add-status'  => { name => 'add_status' },
        'time-unit:s' => { name => 'time_unit', default => 's' },
        'timezone:s'  => { name => 'timezone' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    my $selected = 0;
    foreach ('status', 'interfaces', 'tunnels', 'mistral', 'system') {
        $selected = 1 if (defined($self->{option_results}->{'add_' . $_}));
    }
    if ($selected == 0) {
        $self->{option_results}->{add_status} = 1;
    }

    if ($self->{option_results}->{time_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{time_unit}})) {
        $self->{option_results}->{time_unit} = 's';
    }
    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $inventory = $options{custom}->get_gateway_inventory();

    $self->{global} = { detected => 0 };
    $self->{devices} = {};
    foreach my $device (@$inventory) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $device->{id} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_sn}) && $self->{option_results}->{filter_sn} ne '' &&
            $device->{serialNumber} !~ /$self->{option_results}->{filter_sn}/);

        $self->{global}->{detected}++;

        $self->{devices}->{ $device->{id} } = { sn => $device->{serialNumber} };
        if (defined($self->{option_results}->{add_status}) && defined($device->{status})) {
            $self->{devices}->{ $device->{id} }->{connection} = {
                sn => $device->{serialNumber},
                connectionStatus => lc($device->{status}->{connectedStatus})
            };

            my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
            my $dt = DateTime->from_epoch(epoch => $device->{status}->{statusEpochMilli} / 1000);
            $self->{devices}->{ $device->{id} }->{connection}->{connection_seconds} = time() - $dt->epoch();
            $self->{devices}->{ $device->{id} }->{connection}->{connection_human} = centreon::plugins::misc::change_seconds(
                value => $self->{devices}->{ $device->{id} }->{connection}->{connection_seconds}
            );
        }

        
    }
}

1;

__END__

=head1 MODE

Check devices.

=over 8

=item B<--filter-id>

Filter devices by id.

=item B<--filter-sn>

Filter devices by serial number.

=item B<--unknown-connection-status>

Set unknown threshold for status (Default: '%{connectionStatus} =~ /unknown/i').
Can used special variables like: %{sn}, %{connectionStatus}

=item B<--warning-connection-status>

Set warning threshold for status (Default: '%{connectionStatus} =~ /disconnected/i').
Can used special variables like: %{sn}, %{connectionStatus}

=item B<--critical-connection-status>

Set critical threshold for status.
Can used special variables like: %{sn}, %{connectionStatus}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'devices-detected', 'connection-last-time'.

=back

=cut
