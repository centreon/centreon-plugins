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

package network::huawei::standard::snmp::mode::gpononthealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status %s", $self->{result_values}->{status});
}

sub prefix_module_output {
    my ($self, %options) = @_;

    return sprintf("ONT %s %s(%s) ",
        $options{instance_value}->{display},
        $options{instance_value}->{serial},
        $options{instance_value}->{serial_hex},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'ont',
            type             => 1,
            cb_prefix_output => 'prefix_module_output',
            message_multiple => 'All ONT modules are ok',
            skipped_code     => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{ont} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{status} ne "active"',
            set              =>
                {
                    key_values                     =>
                        [ { name => 'status' }, { name => 'display' } ],
                    closure_custom_output          =>
                        $self->can('custom_status_output'),
                    closure_custom_perfdata        =>
                        sub {return 0;},
                    closure_custom_threshold_check =>
                        \&catalog_status_threshold_ng
                }
        },
        { label => 'temperature', nlabel => 'module.temperature.celsius', set => {
            key_values      => [ { name => 'temperature' } ],
            output_template => 'module temperature: %sC',
            perfdatas       => [
                { template => '%s', unit => 'C' },
            ]
        }
        },
        { label => 'voltage', nlabel => 'module.voltage.volt', display_ok => 0, set => {
            key_values      => [ { name => 'voltage', no_value => 0 } ],
            output_template => 'module voltage: %s V',
            perfdatas       => [
                { template => '%s', unit => 'V' }
            ]
        }
        },
        { label => 'tx-power', nlabel => 'module.tx.power.dbm', set => {
            key_values      => [ { name => 'tx_power' }, { name => 'display' } ],
            output_template => 'Tx Power: %s dBm',
            perfdatas       => [
                { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'rx-power', nlabel => 'module.rx.power.dbm', set => {
            key_values      => [ { name => 'rx_power' }, { name => 'display' } ],
            output_template => 'Rx power: %s dBm',
            perfdatas       => [
                { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'bias-current', nlabel => 'module.bias.current.milliampere', set => {
            key_values      => [ { name => 'bias_current' }, { name => 'display' } ],
            output_template => 'Bias current: %s mA',
            perfdatas       => [
                { template => '%s', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'olt-rx-ont-power', nlabel => 'olt.rx.ont.power.dbm', set => {
            key_values      => [ { name => 'olt_rx_ont_power' }, { name => 'display' } ],
            output_template => 'OLT Rx ONT power: %s dBm',
            perfdatas       => [
                { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
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
        'filter-serial:s' => { name => 'filter_serial' }
    });

    return $self;
}

my $mapping_status = {
    1 => 'active',
    2 => 'notInService',
    3 => 'notReady',
    4 => 'createAndGo',
    5 => 'createAndWait',
    6 => 'destroy'
};

sub get_serial_string($) {
    my ($self) = shift;

    # Get the raw OCTET STRING value for the serial number.
    # It may contain both ASCII and binary data.
    my ($raw_bytes) = @_;

    # Extract the first 4 bytes and interpret them as ASCII characters.
    # Example: '52 43 4D 47' => 'RCMG'
    my $ascii_part = substr($raw_bytes, 0, 4);

    # Extract the last 4 bytes, convert them to an uppercase hex string.
    # Example: '1A 98 0E 53' => '1A980E53'
    my $hex_part = uc(unpack("H*", substr($raw_bytes, 4, 4)));

    # Format the final output string, combining name, serial number, and state.
    # The serial number is shown as: [first 4 bytes as ASCII][last 4 bytes as HEX].
    # Example: RCMG1A980E53
    return "$ascii_part$hex_part";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        serial =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.3' },# hwGponDeviceOntSn
        name   =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9' },# hwGponDeviceOntDespt
        status =>
            { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.10', map => $mapping_status },# hwGponDeviceOntEntryStatus
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $mapping->{serial}->{oid} },
            { oid => $mapping->{name}->{oid} },
            { oid => $mapping->{status}->{oid} }
        ],
        return_type  => 1,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        my $serial_hex = uc(unpack("H*", $result->{serial}));
        my $serial = $self->get_serial_string($result->{serial});

        if (defined($self->{option_results}->{filter_serial}) && $self->{option_results}->{filter_serial} ne '' &&
            $serial !~ /$self->{option_results}->{filter_serial}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $serial . "': no matching filter serial.",
                debug    => 1
            );
            next;
        }

        $self->{ont}{$serial_hex} = {
            instance   => $instance,
            display    => $result->{name},
            serial     => $serial,
            serial_hex => $serial_hex,
            status     => $result->{status}
        };
    }

    if (scalar(keys %{$self->{ont}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no ont associated');
        return;
    }

    $mapping = {
        temperature      => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.1' },
        tx_power         => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.3' },# hwGponOntOpticalDdmTxPower
        rx_power         => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4' },# hwGponOntOpticalDdmRxPower
        voltage          => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.5' },# hwGponOntOpticalDdmVoltage
        olt_rx_ont_power => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.6' },# hwGponOntOpticalDdmOltRxOntPower
    };

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping)) ],
        instances       => [ map($_->{instance}, values %{$self->{ont}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (sort keys %{$self->{ont}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping,
            results  => $snmp_result,
            instance => $self->{ont}->{$_}->{instance}
        );

        $self->{ont}->{$_}->{temperature} = $result->{temperature};
        $self->{ont}->{$_}->{tx_power} = $result->{tx_power} * 0.01;
        $self->{ont}->{$_}->{rx_power} = $result->{rx_power} * 0.01;
        $self->{ont}->{$_}->{voltage} = $result->{voltage} / 1000;
        # Actual value =((Node value - 10000) / 100)
        $self->{ont}->{$_}->{olt_rx_ont_power} = ($result->{olt_rx_ont_power} - 10000) / 100;
    }
}

1;

__END__

=head1 MODE

Shows the ONT health with performance data for power, temperature and voltage for GPON

=over 8

=item B<--filter-serial>

Filter ONT by serial (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{display}>.
C<%(status)> can have one of these values: C<active>, C<notInService>, C<notReady>, C<createAndGo>, C<createAndWait>, C<destroy>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: C<'%{status} ne "active"'>).
You can use the following variables: C<%{status}>, C<%{display}>.
C<%(status)> can have one of these values: C<active>, C<notInService>, C<notReady>, C<createAndGo>, C<createAndWait>, C<destroy>.


=item B<--warning-temperature>

Warning threshold in celsius degrees.

=item B<--critical-temperature>

Critical threshold in celsius degrees

=item B<--warning-voltage>

Warning threshold for the power feed voltage of the optical module (V).

=item B<--critical-voltage>

Critical threshold for the power feed voltage of the optical module (V).

=item B<--warning-tx-power>

Warning threshold for the transmitting power of the optical module (dBm).

=item B<--critical-tx-power>

Critical threshold for the transmitting power of the optical module (dBm).

=item B<--warning-rx-power>

Warning threshold for the receiving power of the optical module (dBm).

=item B<--critical-rx-power>

Critical threshold for the receiving power of the optical module (dBm).

=item B<--warning-bias-current>

Warning threshold for the bias current of the optical module (mA).

=item B<--critical-bias-current>

Critical threshold for the bias current of the optical module (mA).

=item B<--warning-olt-rx-ont-power>

Warning threshold for the ONT optical power received on the OLT (dBm).

=item B<--critical-olt-rx-ont-power>

Critical threshold for the ONT optical power received on the OLT (dBm).

=back

=cut