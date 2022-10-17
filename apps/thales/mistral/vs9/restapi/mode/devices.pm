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
use Digest::MD5;
use DateTime;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'counter') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/bitspersecond/bits/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => 'b',
            instances => [$self->{result_values}->{sn}, $self->{result_values}->{name}],
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => [$self->{result_values}->{sn}, $self->{result_values}->{name}],
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_counter}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);
    return sprintf(
        'traffic %s: %s/s (%s)',
        $self->{result_values}->{label}, $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}
sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{traffic_per_seconds} = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} } - $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} }) / $options{delta_time};
    $self->{result_values}->{traffic_counter} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };

    $self->{result_values}->{traffic_per_seconds} = sprintf('%d', $self->{result_values}->{traffic_per_seconds});

    if (defined($options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}}) &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} ne '' &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} > 0) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{sn} = $options{new_datas}->{$self->{instance} . '_sn'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    return 0;
}

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

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "interface '%s' ",
        $options{instance_value}->{name}
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
                { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'interfaces are ok', display_long => 1, skipped_code => { -10 => 1 } }
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

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'interface-status',
            type => 2,
            warning_default => '%{operatingStatus} !~ /up/i',
            set => {
                key_values => [ { name => 'operatingStatus' }, { name => 'name' }, { name => 'sn' } ],
                output_template => "operating status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'interface-traffic-in', nlabel => 'interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'speed_in' }, { name => 'name' }, { name => 'sn' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'interface-traffic-out', nlabel => 'interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'speed_out' }, { name => 'name' }, { name => 'sn' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'    => { name => 'filter_id' },
        'filter-sn:s'    => { name => 'filter_sn' },
        'add-status'     => { name => 'add_status' },
        'time-unit:s'    => { name => 'time_unit', default => 's' },
        'timezone:s'     => { name => 'timezone' },
        'add-interfaces' => { name => 'add_interfaces' },
        'traffic-unit:s' => { name => 'traffic_unit', default => 'percent_delta' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{checking} = '';
    my $selected = 0;
    foreach ('status', 'interfaces', 'tunnels', 'mistral', 'system') {
        if (defined($self->{option_results}->{'add_' . $_})) {
            $selected = 1;
            $self->{checking} .= $_;
        }
    }
    if ($selected == 0) {
        $self->{option_results}->{add_status} = 1;
    }

    if ($self->{option_results}->{time_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{time_unit}})) {
        $self->{option_results}->{time_unit} = 's';
    }
    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');

    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
        if ($self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
            $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also)");
            $self->{output}->option_exit();
        } else {
            $self->{option_results}->{speed} *= 1000000;
        }
    }

    $self->{option_results}->{traffic_unit} = 'percent_delta'
        if (!defined($self->{option_results}->{traffic_unit}) ||
            $self->{option_results}->{traffic_unit} eq '' ||
            $self->{option_results}->{traffic_unit} eq '%');
    if ($self->{option_results}->{traffic_unit} !~ /^(?:percent|percent_delta|bps|counter)$/) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --traffic-unit');
        $self->{output}->option_exit();
    }
}

sub add_interfaces {
    my ($self, %options) = @_;

    $self->{devices}->{ $options{device}->{id} }->{interfaces} = {};

    my $interfaces = $options{custom}->request_api(endpoint => '/ssIpsecGwHws/' . $options{device}->{id} . '/interfacesStatistics');
    foreach my $interface (@{$interfaces->{listInterfaces}}) {
        $self->{devices}->{ $options{device}->{id} }->{interfaces}->{ $interface->{name} } = {
            name => $interface->{name},
            sn => $options{device}->{serialNumber},
            operatingStatus => $interface->{operatingStatus},
            in => $interface->{interfaceStats}->{inOctets} * 8,
            out => $interface->{interfaceStats}->{outOctets} * 8,
            speed_in => defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' ? $self->{option_results}->{speed} : $interface->{speed},
            speed_out => defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' ? $self->{option_results}->{speed} : $interface->{speed}
        };
    }
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

            $self->{devices}->{ $device->{id} }->{connection}->{connection_seconds} = time() - ($device->{status}->{statusEpochMilli} / 1000);
            $self->{devices}->{ $device->{id} }->{connection}->{connection_human} = centreon::plugins::misc::change_seconds(
                value => $self->{devices}->{ $device->{id} }->{connection}->{connection_seconds}
            );
        }

        $self->add_interfaces(custom => $options{custom}, device => $device)
            if (defined($self->{option_results}->{add_interfaces}));
    }

    $self->{cache_name} = 'thales_mistral_' . $options{custom}->get_connection_info()  . '_' . $self->{mode} . '_' .
        Digest::MD5::md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_id}) ? $self->{option_results}->{filter_id} : '') . '_' .
            (defined($self->{option_results}->{filter_sn}) ? $self->{option_results}->{filter_sn} : '') . '_' .
            $self->{checking}
        );
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

=item B<--unknown-interface-status>

Set unknown threshold for status.
Can used special variables like: %{sn}, %{name}, %{operatingStatus}

=item B<--warning-interface-status>

Set warning threshold for status.
Can used special variables like: %{sn}, %{name}, %{operatingStatus}

=item B<--critical-interface-status>

Set critical threshold for status  (Default: '%{operatingStatus} !~ /up/i').
Can used special variables like: %{sn}, %{name}, %{operatingStatus}

=item B<--timezone>

Set timezone for ntp contact time (Default is 'UTC').

=item B<--time-unit>

Select the time unit for connection threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--traffic-unit>

Units of thresholds for the traffic (Default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--speed>

Set interface speed (in Mb).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'devices-detected', 'connection-last-time',
'interface-traffic-in', 'interface-traffic-out'.

=back

=cut
