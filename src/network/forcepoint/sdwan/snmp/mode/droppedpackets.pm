#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::forcepoint::sdwan::snmp::mode::droppedpackets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_drop_calc {
    my ($self, %options) = @_;

    # First call or reboot or counter goes back
    if (!defined($options{old_datas}->{global_dropped})
        || $options{new_datas}->{global_dropped} < $options{old_datas}->{global_dropped}
    ) {
        $self->{error_msg} = 'buffer creation';
        return -1;
    }

    my $dropped = $options{new_datas}->{global_dropped} - $options{old_datas}->{global_dropped};
    $self->{result_values}->{dropped_packets_per_sec} = $dropped / $options{delta_time};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'dropped-packets-sec',
            nlabel => 'dropped.packets.persecond',
            set    => {
                key_values          => [],
                manual_keys         => 1,
                closure_custom_calc => $self->can('custom_drop_calc'),
                output_template     => 'Packets Dropped : %.2f /s',
                output_use          => 'dropped_packets_per_sec', threshold_use => 'dropped_packets_per_sec',
                perfdatas           => [
                    { value => 'dropped_packets_per_sec', template => '%.2f', unit => 'packets/s', min => 0 }
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    $self->{cache_policy} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }

    my $oid_fwDropped = '.1.3.6.1.4.1.47565.1.1.1.6.0';
    my $result = $options{snmp}->get_leef(oids => [ $oid_fwDropped ], nothing_quit => 1);

    $self->{global} = {
        dropped => $result->{$oid_fwDropped}
    };

    $self->{cache_name} = "forcepoint_sdwan_" . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all'));
}

1;

__END__

=head1 MODE

Check dropped packets per second by firewall.

=over 8

=item B<--warning-dropped-packets-sec>

Threshold in packets/s.

=item B<--critical-dropped-packets-sec>

Threshold in packets/s.

=back

=cut
