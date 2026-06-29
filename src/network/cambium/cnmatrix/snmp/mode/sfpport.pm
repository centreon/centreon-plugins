#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package network::cambium::cnmatrix::snmp::mode::sfpport;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::statefile;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use Safe;

sub prefix_sfp_output {
    my ($self, %options) = @_;

    my $foo = sprintf(
        "sfp port '%s'%s%s%s ",
        $options{instance},
        $options{instance_value}->{interface} ne '' ? ' - ' . $options{instance_value}->{interface} : '',
        $options{instance_value}->{serial} ne '' ? ' - serial: ' . $options{instance_value}->{serial} : '',
        $options{instance_value}->{type} ne '' ? ' - type: ' . $options{instance_value}->{type} : ''
    );

    return $foo;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'sfp',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_sfp_output',
            message_multiple => 'All sfp ports are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{sfp} = [
        { label => 'input-power', nlabel => 'interface.input.power.dbm', display_ok => 0, set => {
            key_values      => [ { name => 'input_power' }, { name => 'display' } ],
            output_template => 'Input Power : %s dBm',
            perfdatas       => [
                { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'bias-current', nlabel => 'interface.bias.current.milliampere', display_ok => 0, set => {
            key_values      => [ { name => 'bias_current' }, { name => 'display' } ],
            output_template => 'Bias Current : %s mA',
            perfdatas       => [
                { template => '%s', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'output-power', nlabel => 'interface.output.power.dbm', display_ok => 0, set => {
            key_values      => [ { name => 'output_power' }, { name => 'display' } ],
            output_template => 'Output Power : %s dBm',
            perfdatas       => [
                { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'voltage', nlabel => 'interface.voltage.volt', display_ok => 0, set => {
            key_values      => [ { name => 'voltage' }, { name => 'display' } ],
            output_template => 'Voltage : %s V',
            perfdatas       => [
                { template => '%s', unit => 'V', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'module-temperature', nlabel => 'interface.module.temperature.celsius', display_ok => 0, set =>
            {
                key_values      => [ { name => 'module_temperature' }, { name => 'display' } ],
                output_template => 'Module Temperature : %.2f C',
                perfdatas       => [
                    { template => '%.2f', unit => 'C', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'include-port:s'          => { name => 'include_port' },
            'exclude-port:s'          => { name => 'exclude_port' },
            'include-serial:s'        => { name => 'include_serial' },
            'exclude-serial:s'        => { name => 'exclude_serial' },
            'include-interface:s'     => { name => 'include_interface' },
            'exclude-interface:s'     => { name => 'exclude_interface' },
            'add-interface-name'      => { name => 'add_interface_name' },
            'reload-cache-time:s'     => { name => 'reload_cache_time', default => 180 },
            'show-cache'              => { name => 'show_cache' },
            'display-transform-src:s' => { name => 'display_transform_src' },
            'display-transform-dst:s' => { name => 'display_transform_dst' }
        }
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    $self->{safe} = Safe->new();
    $self->{safe}->share('$assign_var');

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    $self->{statefile_cache}->check_options(%options);
}

my $map_type = {
    1  => 'cn1000BASE-T',
    2  => 'cn1000BASE-CX',
    3  => 'cn1000BASE-LX',
    4  => 'cn1000BASE-SX',
    5  => 'cn10GBASE-SR',
    6  => 'cn10GBASE-LR',
    7  => 'cn10GBASE-ER',
    8  => 'cn10GBASE-LRM',
    9  => 'cn10GBASE-SW',
    10 => 'cn10GBASE-LW',
    11 => 'cn10GBASE-EW'
};

my $mapping = {
    serial            => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.9' },# cnTransceiverVendorSerial
    type              => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.3', map => $map_type },# cnTransceiverType
    outputPower       => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.14' },# cnTransceiverTxPower
    inputPower        => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.15' },# cnTransceiverRxPower
    biasCurrent       => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.13' },# cnTransceiverTxBias
    voltage           => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.12' },# cnTransceiverVoltage
    moduleTemperature => { oid => '.1.3.6.1.4.1.2076.81.18.1.1.11.1.11' },# cnTransceiverTemperature
};

sub reload_cache {
    my ($self, %options) = @_;
    my $datas = {};

    $datas->{last_timestamp} = time();
    $datas->{sfp} = {};
    my $snmp_names = {};

    if (defined($self->{option_results}->{add_interface_name}) || defined($self->{option_results}->{add_interface_name})) {
        my $oid_interface_name = '.1.3.6.1.2.1.31.1.1.1.1';
        my $result = $options{snmp}->get_table(
            oid => $oid_interface_name,
        );

        foreach my $key (keys %$result) {
            next if $key !~ /^$oid_interface_name\.(.*)$/;
            my $instance = $1;

            $snmp_names->{$instance} = $self->{output}->decode($result->{$key});
        }
    }

    my $result = $options{snmp}->get_table(
        oid => $mapping->{serial}->{oid},
    );

    foreach my $key (keys %$result) {
        next if ($key !~ /$mapping->{serial}->{oid}\.([0-9]+)$/);
        my $instance = $1;

        $datas->{sfp}->{$instance} = [
            $self->{output}->decode($result->{$mapping->{serial}->{oid} . '.' . $instance}),
            exists($snmp_names->{$instance}) ? $snmp_names->{$instance} : ""
        ];
    }

    if (scalar(keys %{$datas->{sfp}}) <= 0) {
        $self->{output}->option_exit(short_msg => "Can't construct cache...");
    }

    $self->{statefile_cache}->write(data => $datas);
    return $datas->{sfp};
}

sub get_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile =>
        'cache_snmpstandard_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->option_exit(long_msg => $self->{statefile_cache}->get_string_content());
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $sfp_ports = $self->{statefile_cache}->get(name => 'sfp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || !defined($sfp_ports) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $sfp_ports = $self->reload_cache(snmp => $options{snmp});
        $self->{statefile_cache}->read();
    }

    my $results = {};
    foreach (keys %$sfp_ports) {
        next if is_excluded(
            $_,
            $self->{option_results}->{include_port},
            $self->{option_results}->{exclude_port},
            output => $self->{output}
        );
        next if is_excluded($sfp_ports->{$_}->[0],
            $self->{option_results}->{include_serial},
            $self->{option_results}->{exclude_serial},
            output => $self->{output}
        );
        next if is_excluded($sfp_ports->{$_}->[1],
            $self->{option_results}->{include_interface},
            $self->{option_results}->{exclude_interface},
            output => $self->{output}
        );

        $results->{$_} = $sfp_ports->{$_};
    }

    if (scalar(keys %$results) <= 0) {
        $self->{output}->option_exit(short_msg => "No sfp ports found. Can be: filters, cache file.");
    }

    return $results;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $sfp_ports = $self->get_selection(snmp => $options{snmp});

    $options{snmp}->load(
        oids         => [ map($_->{oid}, values(%$mapping)) ],
        instances    => [ keys %$sfp_ports ],
        nothing_quit => 1
    );
    my $snmp_result = $options{snmp}->get_leef();

    $self->{sfp} = {};

    foreach (keys %$sfp_ports) {
        my $instance = $_;

        my $result = $options{snmp}->map_instance(
            mapping  => $mapping,
            results  => $snmp_result,
            instance => $instance
        );

        my $display = defined($self->{option_results}->{add_interface_name}) ?
            $instance . '-' . exists($sfp_ports->{$instance}->[1]) ? $sfp_ports->{$instance}->[1] : '' : $instance;
        $display = $self->get_display_value(value => $display);

        $self->{sfp}->{$instance}->{interface} = defined($self->{option_results}->{add_interface_name}) &&
            exists($sfp_ports->{$instance}->[1]) ?
            $sfp_ports->{$instance}->[1] :
            '';

        $self->{sfp}->{$instance}->{port} = $instance;
        ($result->{serial}) =~ s/^\s+|\s+$//g;
        $self->{sfp}->{$instance}->{serial} = $result->{serial};
        $self->{sfp}->{$instance}->{type} = $result->{type};

        $self->{sfp}->{$instance}->{input_power} = undef;
        if (defined($result->{inputPower}) && $result->{inputPower} != 0 && $result->{inputPower} != -32768) {
            $self->{sfp}->{$instance}->{input_power} = $result->{inputPower} / 1000;
        }

        $self->{sfp}->{$instance}->{output_power} = undef;
        if (defined($result->{outputPower}) && $result->{outputPower} != 0 && $result->{outputPower} != -32768) {
            $self->{sfp}->{$instance}->{output_power} = $result->{outputPower} / 1000;
        }

        $self->{sfp}->{$instance}->{bias_current} = undef;
        if (defined($result->{biasCurrent}) && $result->{biasCurrent} != 0 && $result->{biasCurrent} != -32768) {
            $self->{sfp}->{$instance}->{bias_current} = $result->{biasCurrent} / 1000;
        }

        $self->{sfp}->{$instance}->{voltage} = undef;
        if (defined($result->{biasCurrent}) && $result->{voltage} != 0 && $result->{voltage} != -32768) {
            $self->{sfp}->{$instance}->{voltage} = $result->{voltage} / 1000;
        }

        $self->{sfp}->{$instance}->{module_temperature} = undef;
        if (defined($result->{biasCurrent}) && $result->{moduleTemperature} != 0 && $result->{moduleTemperature} != -32768) {
            $self->{sfp}->{$instance}->{module_temperature} = $result->{moduleTemperature};
        }

        $self->{sfp}->{$instance}->{display} = $display;

    }
}

sub get_display_value {
    my ($self, %options) = @_;

    our $assign_var = $options{value};
    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));

        $self->{safe}->reval("\$assign_var =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}",
            1);
        if ($@) {
            die 'Unsafe code evaluation: ' . $@;
        }
    }

    return $assign_var;
}

1;

__END__

=head1 MODE

Check C<SFP> port.

=over 8

=item B<--include-port>

Filter ports by index (can be a regexp).

=item B<--exclude-port>

Exclude ports by index (can be a regexp).

=item B<--include-serial>

Filter ports by serial (can be a regexp).

=item B<--exclude-serial>

Exclude ports by serial (can be a regexp).

=item B<--include-interface>

Filter ports by interface name (can be a regexp). Can be used only together with --add-interface-name.

=item B<--exclude-interface>

Exclude ports by interface name (can be a regexp). Can be used only together with --add-interface-name.

=item B<--add-interface-name>

Add the corresponding interface name when set. Used for the instance name in performance data, too.

=item B<--warning-input-power>

Thresholds (dBm).

=item B<--critical-input-power>

Thresholds (dBm).

=item B<--warning-output-power>

Thresholds (dBm).

=item B<--critical-output-power>

Thresholds (dBm).

=item B<--warning-bias-current>

Thresholds (mA).

=item B<--critical-bias-current>

Thresholds (mA).

=item B<--warning-voltage>

Thresholds (V).

=item B<--critical-voltage>

Thresholds (V).

=item B<--warning-module-temperature>

Thresholds (C).

=item B<--critical-module-temperature>

Thresholds (C).

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding C<--display-transform-src='eth' --display-transform-dst='ens'>  will replace all occurrences of 'eth' with 'ens'

=item B<--show-cache>

Display cache interface data.

=back

=cut
