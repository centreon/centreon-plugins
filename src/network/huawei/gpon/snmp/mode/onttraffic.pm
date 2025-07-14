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

package network::huawei::gpon::snmp::mode::onttraffic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_module_output {
    my ($self, %options) = @_;

    return sprintf("ONT %s %s(%s) ",
        $options{instance_value}->{display},
        $options{instance_value}->{serial_hex},
        $options{instance_value}->{serial}
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
        { label => 'traffic-in', nlabel => 'ont.traffic.in.bitspersecond', set => {
            key_values          => [
                { name => 'up_bytes', per_second => 1 }, { name => 'display' }
            ],
            output_template     => 'traffic in: %.2f %s/s',
            output_change_bytes => 2,
            perfdatas           => [
                { template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'traffic-out', nlabel => 'ont.traffic.out.bitspersecond', set => {
            key_values          => [
                { name => 'down_bytes', per_second => 1 }, { name => 'display' }
            ],
            output_template     => 'traffic in: %.2f %s/s',
            output_change_bytes => 2,
            perfdatas           => [
                { template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'up-packets', nlabel => 'ont.packets.up.persecond', set => {
            key_values      => [ { name => 'up_packets', per_second => 1 } ],
            output_template => 'Up packets (per sec): %d',
            perfdatas       => [
                { label => 'up_packets', template => '%d', min => 0, unit => 'packets/s' }
            ]
        }
        },
        { label => 'down-packets', nlabel => 'ont.packets.down.persecond', set => {
            key_values      => [ { name => 'down_packets', per_second => 1 } ],
            output_template => 'Down packets (per sec): %d',
            perfdatas       => [
                { label => 'down_packets', template => '%d', min => 0, unit => 'packets/s' }
            ]
        }
        },
        { label => 'up-drop-packets', nlabel => 'ont.packets.up.drop.persecond', set => {
            key_values      => [ { name => 'up_drop_packets', per_second => 1 } ],
            output_template => 'Up dropped packets (per sec): %d',
            perfdatas       => [
                { label => 'up_drop_packets', template => '%d', min => 0, unit => 'packets/s' }
            ]
        }
        },
        { label => 'down-drop-packets', nlabel => 'ont.packets.down.drop.persecond', set => {
            key_values      => [ { name => 'down_drop_packets', per_second => 1 } ],
            output_template => 'Down drop packets (per sec): %d',
            perfdatas       => [
                { label => 'down_drop_packets', template => '%d', min => 0, unit => 'packets/s' }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-serial:s' => { name => 'filter_serial' }
    });

    return $self;
}

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

    $self->{cache_name} = 'huawei_gpon_' . $self->{mode} . '_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_serial}) ?
            md5_hex($self->{option_results}->{filter_serial}) :
            md5_hex('all'));

    my $mapping = {
        serial => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.3' },# hwGponDeviceOntSn
        name   => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9' },# hwGponDeviceOntDespt
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [ { oid => $mapping->{serial}->{oid} }, { oid => $mapping->{name}->{oid} }, ],
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
                long_msg => "skipping '" . $serial . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        $self->{ont}{$serial_hex} = {
            instance   => $instance,
            display    => $result->{name},
            serial     => $serial,
            serial_hex => $serial_hex,
        };
    }

    if (scalar(keys %{$self->{ont}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no ont associated');
        return;
    }

    $mapping = {
        up_packets        => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.4.23.1.1' },# hwGponOntStatisticUpPackts
        down_packets      => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.4.23.1.2' },# hwGponOntStatisticDownPackts
        up_bytes          => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.4.23.1.3' },# hwGponOntStatisticUpBytes
        down_bytes        => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.4.23.1.4' },# hwGponOntStatisticDownBytes
        up_drop_packets   => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.4.23.1.5' },# hwGponOntStatisticUpDropPackts
        down_drop_packets => { oid => '.1.3.6.1.4.1.2011.6.128.1.1.4.23.1.6' },# hwGponOntStatisticDownDropPackts
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

        $self->{ont}->{$_}->{up_packets} = $result->{up_packets};
        $self->{ont}->{$_}->{down_packets} = $result->{down_packets};
        $self->{ont}->{$_}->{up_bytes} = $result->{up_bytes};
        $self->{ont}->{$_}->{down_bytes} = $result->{down_bytes};
        $self->{ont}->{$_}->{up_drop_packets} = $result->{up_drop_packets};
        $self->{ont}->{$_}->{down_drop_packets} = $result->{down_drop_packets};
    }
}

1;

__END__

=head1 MODE

Shows the traffic on the ONT module

=over 8

=item B<--filter-serial>

Filter otn by serial (can be a regexp).

=item B<--warning-traffic-in>

Warning threshold for the downstream bytes (b/s).

=item B<--critical-traffic-in>

Critical threshold for the downstream bytes (b/s).

=item B<--warning-traffic-out>

Warning threshold for the upstream bytes (b/s).

=item B<--critical-traffic-out>

Critical threshold for the upstream bytes (b/s).

=item B<--warning-down-packets>

Warning threshold for the downstream frames. (packets/s)

=item B<--critical-down-packets>

Critical threshold for the downstream frames. (packets/s)

=item B<--warning-up-packets>

Warning threshold for the upstream frames. (packets/s)

=item B<--critical-up-packets>

Critical threshold for the upstream frames. (packets/s)

=item B<--warning-up-drop-packets>

Warning threshold for the upstream discarded frames. (packets/s)

=item B<--critical-up-drop-packets>

Critical threshold for the upstream discarded frames. (packets/s)

=item B<--warning-down-drop-packets>

Warning threshold for the downstream discarded frames. (packets/s)

=item B<--critical-down-drop-packets>

Critical threshold for the downstream discarded frames. (packets/s)

=back

=cut