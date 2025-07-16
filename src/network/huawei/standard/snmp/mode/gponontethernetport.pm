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

package network::huawei::standard::snmp::mode::gponontethernetport;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status %s", $self->{result_values}->{online_state});
}

sub prefix_module_output {
    my ($self, %options) = @_;

    return sprintf("ONT '%s' - %s(%s) ethernet port %d (%s) ",
        $options{instance_value}->{display},
        $options{instance_value}->{serial},
        $options{instance_value}->{serial_hex},
        $options{instance_value}->{port_id},
        $options{instance_value}->{speed}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'ethernet_ports',
            type             => 1,
            cb_prefix_output => 'prefix_module_output',
            message_multiple => 'All ONT ethernet port are ok',
            skipped_code     => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{ethernet_ports} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{online_state} ne "linkup" || %{speed} eq "invalid"',
            set              =>
                {
                    key_values                     => [
                        { name => 'online_state' },
                        { name => 'display' },
                        { name => 'speed' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
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
        'filter-serial:s' => { name => 'filter_serial' }
    });

    return $self;
}

my $mapping_online_status = {
    1  => 'linkup',
    2  => 'linkdown',
    -1 => 'invalid'
};

my $mapping_speed = {
    1  => 'speed10M',
    2  => 'speed100M',
    3  => 'speed1000M',
    4  => 'autoneg',
    5  => 'autospeed10M',
    6  => 'autospeed100M',
    7  => 'autospeed1000M',
    8  => 'speed10G',
    9  => 'autospeed10G',
    10 => 'speed2500M',
    11 => 'autospeed2500M',
    12 => 'speed5000M',
    13 => 'autospeed5000M',
    14 => 'speed25000M',
    15 => 'autospeed25000M',
    16 => 'speed40000M',
    17 => 'autospeed40000M',
    -1 => 'invalid'
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
        serial => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.3' },# hwGponDeviceOntSn
        name   => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9' }# hwGponDeviceOntDespt
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [ { oid => $mapping->{serial}->{oid} }, { oid => $mapping->{name}->{oid} } ],
        return_type  => 1,
        nothing_quit => 1
    );

    my %ont = ();

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        my $serial = $self->get_serial_string($result->{serial});

        if (defined($self->{option_results}->{filter_serial}) && $self->{option_results}->{filter_serial} ne '' &&
            $serial !~ /$self->{option_results}->{filter_serial}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $serial . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        $ont{$instance} = {
            name       => $result->{name},
            serial     => $serial,
            serial_hex => uc(unpack("H*", $result->{serial})),
        };
    }

    if (scalar(keys %ont) <= 0) {
        $self->{output}->output_add(long_msg => 'no ethernet_ports associated');
        return;
    }

    $mapping = {
        online_state => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.22', map => $mapping_online_status },
        speed        => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.4', map => $mapping_speed }
    };

    $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [ { oid => $mapping->{online_state}->{oid} }, { oid => $mapping->{speed}->{oid} } ],
        return_type  => 1,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{online_state}->{oid}\.(.*)$/);
        my $ont_instance = $1;
        my ($ont_index, $port_id) = $ont_instance =~ /^(.*)\.([^.]+)$/;

        if (defined($ont{$ont_index})) {
            my $result = $options{snmp}->map_instance(
                mapping  => $mapping,
                results  => $snmp_result,
                instance => $ont_instance
            );

            my $port_instance = $ont_index . '-' . $port_id;

            $self->{ethernet_ports}->{$port_instance} = {
                online_state => $result->{online_state},
                speed        => $result->{speed},
                port_id      => $port_id,
                instance     => $port_instance,
                display      => $ont{$ont_index}->{name},
                serial       => $ont{$ont_index}->{serial},
                serial_hex   => $ont{$ont_index}->{serial_hex},
            };
        }
    }
}

1;

__END__

=head1 MODE

Shows the status of a ONT module ETH port for GPON

=over 8

=item B<--filter-serial>

Filter ONT by serial (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{online_state}>, C<%{display}>, C<%(speed)>.
C<%(online_state)> can have one of these values: C<linkup>, C<linkdown>, C<invalid>.
C<%(speed)> can have one of these values: C<speed10M>, C<speed100M>, C<speed1000M>, C<autoneg>, C<autospeed10M>,
C<autospeed100M>, C<autospeed1000M>, C<speed10G>, C<autospeed10G>, C<speed2500M>, C<autospeed2500M>, C<speed5000M>,
C<autospeed5000M>, C<speed25000M>, C<autospeed25000M>, C<speed40000M>, C<autospeed40000M>, C<invalid>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: C<'%{online_state} ne "linkup" || %{speed} eq "invalid"'>).
You can use the following variables: C<%{online_state}>, C<%{display}>, C<%(speed)>.
C<%(online_state)> can have one of these values: C<linkup>, C<linkdown>, C<invalid>.
C<%(speed)> can have one of these values: C<speed10M>, C<speed100M>, C<speed1000M>, C<autoneg>, C<autospeed10M>,
C<autospeed100M>, C<autospeed1000M>, C<speed10G>, C<autospeed10G>, C<speed2500M>, C<autospeed2500M>, C<speed5000M>,
C<autospeed5000M>, C<speed25000M>, C<autospeed25000M>, C<speed40000M>, C<autospeed40000M>, C<invalid>

=back

=cut