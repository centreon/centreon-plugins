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

package network::ubiquiti::uap::snmp::mode::vaphealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state is %s',
        $self->{result_values}->{state}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Virtual Access points ';
}

sub ap_long_output {
    my ($self, %options) = @_;

    return sprintf(
        'virtual access point %s - BSS ID %s - ESS ID %s ',
        $options{instance_value}->{display},
        $options{instance_value}->{bss_id},
        $options{instance_value}->{ess_id}
    );
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "virtual access point '" . $options{instance_value}->{display} . "' ";
}

sub custom_dropped_output {
    my ($self, %options) = @_;

    return sprintf(
        'packets %s dropped: %.2f %% (%d/%d packets)',
        $self->{result_values}->{label_ref},
        $self->{result_values}->{dropped_prct},
        $self->{result_values}->{dropped}, $self->{result_values}->{packets}
    );
}

sub custom_dropped_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{dropped} = $options{new_datas}->{$self->{instance} . '_dropped_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{packets} = $options{new_datas}->{$self->{instance} . '_packets_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{label_ref} = $options{extra_options}->{label_ref};
    $self->{result_values}->{dropped_prct} = 0;
    if ($self->{result_values}->{packets} > 0) {
        $self->{result_values}->{dropped_prct} = $self->{result_values}->{dropped} * 100 / $self->{result_values}->{packets};
    }

    return 0;
}

sub custom_error_output {
    my ($self, %options) = @_;

    return sprintf(
        'packets %s dropped: %.2f %% (%d/%d packets)',
        $self->{result_values}->{label_ref},
        $self->{result_values}->{error_prct},
        $self->{result_values}->{error}, $self->{result_values}->{packets}
    );
}

sub custom_error_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{error} = $options{new_datas}->{$self->{instance} . '_error_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{packets} = $options{new_datas}->{$self->{instance} . '_packets_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{label_ref} = $options{extra_options}->{label_ref};
    $self->{result_values}->{error_prct} = 0;
    if ($self->{result_values}->{packets} > 0) {
        $self->{result_values}->{error_prct} = $self->{result_values}->{error} * 100 / $self->{result_values}->{packets};
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name                 => 'vap',
            type               => 3,
            cb_prefix_output   => 'prefix_ap_output',
            cb_long_output     => 'ap_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All virtual access points are ok',
            group              => [
                { name => 'health', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{health} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{state} eq "down"',
            set              =>
                {
                    key_values                     => [ { name => 'state' } ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'channel', nlabel => 'vap.channel.count', display_ok => 0, set => {
            key_values      => [ { name => 'channel' }, { name => 'display' } ],
            output_template => 'virtual access point channels: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'extended-channel', nlabel => 'vap.extended.channel.count', display_ok => 0, set => {
            key_values      => [ { name => 'ext_channel' }, { name => 'display' } ],
            output_template => 'virtual access point extended channels: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'number-stations', nlabel => 'vap.number.stations.count', display_ok => 0, set => {
            key_values      => [ { name => 'num_stations' }, { name => 'display' } ],
            output_template => 'virtual access point number stations: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'traffic-in', nlabel => 'vap.traffic.in.bitspersecond', display_ok => 0, set => {
            key_values          => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
            output_change_bytes => 2,
            output_template     => 'Traffic In : %s %s/s',
            perfdatas           => [
                { label => 'traffic_in', template => '%.2f',
                    min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'traffic-out', nlabel => 'vap.traffic.out.bitspersecond', display_ok => 0, set => {
            key_values          => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
            output_change_bytes => 2,
            output_template     => 'Traffic Out : %s %s/s',
            perfdatas           => [
                { label => 'traffic_out', template => '%.2f',
                    min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'dropped-in', nlabel => 'vap.packets.in.dropped.percentage', display_ok => 0, set => {
            key_values                        =>
                [ { name => 'display' }, { name => 'packets_in' }, { name => 'dropped_in' } ],
            closure_custom_calc               => $self->can('custom_dropped_calc'),
            closure_custom_calc_extra_options => { label_ref => 'in' },
            closure_custom_output             => $self->can('custom_dropped_output'),
            threshold_use                     => 'dropped_prct',
            perfdatas                         =>
                [
                    { label => 'packets_dropped_in', value => 'dropped_prct', template => '%s', unit => '%',
                        min => 0, max => 100, label_extra_instance => 1 }
                ]
        }
        },
        { label => 'dropped-out', nlabel => 'vap.packets.out.dropped.percentage', display_ok => 0, set => {
            key_values                        =>
                [ { name => 'display' }, { name => 'packets_out' }, { name => 'dropped_out' } ],
            closure_custom_calc               => $self->can('custom_dropped_calc'),
            closure_custom_calc_extra_options => { label_ref => 'out' },
            closure_custom_output             => $self->can('custom_dropped_output'),
            threshold_use                     => 'dropped_prct',
            perfdatas                         =>
                [
                    { label => 'packets_dropped_out', value => 'dropped_prct', template => '%s', unit => '%',
                        min => 0, max => 100, label_extra_instance => 1 }
                ]
        }
        },
        { label => 'error-in', nlabel => 'vap.packets.in.error.percentage', display_ok => 0, set => {
            key_values                        =>
                [ { name => 'display' }, { name => 'packets_in' }, { name => 'error_in' } ],
            closure_custom_calc               => $self->can('custom_error_calc'),
            closure_custom_calc_extra_options => { label_ref => 'in' },
            closure_custom_output             => $self->can('custom_error_output'),
            threshold_use                     => 'error_prct',
            perfdatas                         =>
                [
                    { label => 'packets_error_in', value => 'error_prct', template => '%s', unit => '%',
                        min => 0, max => 100, label_extra_instance => 1 }
                ]
        }
        },
        { label => 'error-out', nlabel => 'vap.packets.out.error.percentage', display_ok => 0, set => {
            key_values                        =>
                [ { name => 'display' }, { name => 'packets_out' }, { name => 'error_out' } ],
            closure_custom_calc               => $self->can('custom_error_calc'),
            closure_custom_calc_extra_options => { label_ref => 'out' },
            closure_custom_output             => $self->can('custom_error_output'),
            threshold_use                     => 'error_prct',
            perfdatas                         =>
                [
                    { label => 'packets_error_out', value => 'error_prct', template => '%s', unit => '%',
                        min => 0, max => 100, label_extra_instance => 1 }
                ]
        }
        },
        { label => 'output-power', nlabel => 'vap.output.power.dbm', display_ok => 0, set => {
            key_values            =>
                [ { name => 'output_power' }, { name => 'display' } ],
            output_template       =>
                'virtual access point output power : %s dBm',
            output_error_template =>
                'Output Power : %s',
            perfdatas             =>
                [
                    { label  => 'output_power', template => '%s',
                        unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    name => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.7' },# unifiVapName
};

my $map_state = { 0 => 'down', 1 => 'up' };

my $mapping_stat = {
    channel     => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.4' },# unifiVapChannel
    extChannel  => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.5' },# unifiExtVapChannel
    numStations => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.8' },# unifiVapNumStations
    radio       => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.9' },# unifiVapRadio
    rxBytes     => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.10' },# unifiVapRxBytes
    rxDropped   => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.12' },# unifiVapRxDropped
    rxErrors    => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.13' },# unifiVapRxErrors
    rxPackets   => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.15' },# unifiVapRxPackets
    txBytes     => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.16' },# unifiVapTxBytes
    txDropped   => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.17' },# unifiVapTxDropped
    txErrors    => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.18' },# unifiVapTxErrors
    txPackets   => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.19' },# unifiVapTxPackets
    txPower     => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.21' },# unifiVapTxPower
    bssId       => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.2' },# unifiVapBssId
    essId       => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.6' },# unifiVapEssId
    txUp        => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.22', map => $map_state },# unifiVapUp
    usage       => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.23' }#  unifiVapUsage
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vap} = {};

    my $request = [ { oid => $mapping->{name}->{oid} } ];

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => $request,
        return_type  => 1,
        nothing_quit => 1
    );

    foreach (sort keys %$snmp_result) {
        next if (!/^$mapping->{name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(long_msg =>
                "skipping Virtual Access Point '$instance': cannot get a name. please set it.",
                debug                            => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{name} . "': no matching name filter.",
                debug                            => 1);
            next;
        }

        $self->{vap}->{ $result->{name} } = {
            instance => $instance,
            display  => $result->{name},
            health   => {
                display => $result->{name}
            }
        };
    }

    if (scalar(keys %{$self->{vap}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no AP associated');
        return;
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping_stat)) ],
        instances       => [ map($_->{instance}, values %{$self->{vap}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (sort keys %{$self->{vap}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping_stat,
            results  => $snmp_result,
            instance => $self->{vap}->{$_}->{instance}
        );

        my $mac = join('-', uc(unpack("H*", $result->{bssId})) =~ /(..)/g);

        $self->{vap}->{$_}->{bss_id} = $mac;
        $self->{vap}->{$_}->{ess_id} = $result->{essId};
        $self->{vap}->{$_}->{health}->{radio} = $result->{radio};

        $self->{vap}->{$_}->{health}->{state} = $result->{txUp};
        $self->{vap}->{$_}->{health}->{usage} = $result->{usage};

        $self->{vap}->{$_}->{health}->{channel} = $result->{channel};
        $self->{vap}->{$_}->{health}->{ext_channel} = $result->{extChannel};
        $self->{vap}->{$_}->{health}->{num_stations} = $result->{numStations};

        $self->{vap}->{$_}->{health}->{traffic_in} = $result->{rxBytes} * 8;
        $self->{vap}->{$_}->{health}->{traffic_out} = $result->{txBytes} * 8;

        $self->{vap}->{$_}->{health}->{dropped_in} = $result->{rxDropped};
        $self->{vap}->{$_}->{health}->{dropped_out} = $result->{txDropped};

        $self->{vap}->{$_}->{health}->{error_in} = $result->{rxErrors};
        $self->{vap}->{$_}->{health}->{error_out} = $result->{txErrors};

        $self->{vap}->{$_}->{health}->{packets_in} = $result->{rxPackets};
        $self->{vap}->{$_}->{health}->{packets_out} = $result->{txPackets};

        $self->{vap}->{$_}->{health}->{output_power} = $result->{txPower};
    }

    $self->{cache_name} = 'ubiquiti_uap_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ?
            md5_hex($self->{option_results}->{filter_name}) :
            md5_hex('all'));
}

1;

__END__

=head1 MODE

Check AP health.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^traffic-in$'

=item B<--filter-name>

Filter access point name (can be a regexp)

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. (default: '').
You can use the following variables: %{state}, %{radio}, %{usage}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} eq "down"').
You can use the following variables: %{state}, %{radio}, %{usage}, %{display}

=item B<--warning-channel>

Warning thresholds for number of channels.

=item B<--critical-channel>

Critical thresholds for number of channels.

=item B<--warning-extended-channel>

Warning thresholds for number of extended channels.

=item B<--critical-extended-channel>

Critical thresholds for number of extended channels.

=item B<--warning-number-stations>

Warning thresholds for number of stations.

=item B<--critical-number-stations>

Critical thresholds for number of stations.

=item B<--warning-traffic-in>

Warning threshold for traffic in (b/s).

=item B<--critical-traffic-in>

Critical threshold for traffic in (b/s).

=item B<--warning-traffic-out>

Warning threshold for traffic out (b/s).

=item B<--critical-traffic-out>

Critical threshold for traffic out (b/s).

=item B<--warning-dropped-in>

Warning thresholds for dropped packets in (%)

=item B<--critical-dropped--in>

Critical thresholds for dropped packets in (%)

=item B<--warning-dropped-out>

Warning thresholds for dropped packets out (%)

=item B<--critical-dropped-out>

Critical thresholds for dropped packets out (%)

=item B<--warning-error-in>

Warning thresholds for error packets in (%)

=item B<--critical-error-in>

Critical thresholds for error packets in (%)

=item B<--warning-error-out>

Warning thresholds for error packets out (%)

=item B<--critical-error-out>

Critical thresholds for error packets out (%)

=item B<--warning-output-power>

Warning thresholds for output power (dBm).

=item B<--critical-output-power>

Critical thresholds for output power (dBm).

=back

=cut
