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

package network::forcepoint::sdwan::snmp::mode::rejectedpackets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_reject_calc {
    my ($self, %options) = @_;

    # First call or reboot or counter goes back
    if (!defined($options{old_datas}->{global_rejected})
        || $options{new_datas}->{global_rejected} < $options{old_datas}->{global_rejected}
    ) {
        $self->{error_msg} = 'buffer creation';
        return -1;
    }

    my $rejected = $options{new_datas}->{global_rejected} - $options{old_datas}->{global_rejected};
    $self->{result_values}->{rejected_packets_per_sec} = $rejected / $options{delta_time};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'rejected-packets-sec',
            nlabel => 'rejected.packets.persecond',
            set    => {
                key_values          => [],
                manual_keys         => 1,
                closure_custom_calc => $self->can('custom_reject_calc'),
                output_template     => 'Packets Rejected : %.2f /s',
                output_use          => 'rejected_packets_per_sec', threshold_use => 'rejected_packets_per_sec',
                perfdatas           => [
                    { value => 'rejected_packets_per_sec', template => '%.2f', unit => 'packets/s', min => 0 }
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

    my $oid_fwRejected = '.1.3.6.1.4.1.47565.1.1.1.9.0';
    my $result = $options{snmp}->get_leef(oids => [ $oid_fwRejected ], nothing_quit => 1);

    $self->{global} = {
        rejected => $result->{$oid_fwRejected}
    };

    $self->{cache_name} = "forcepoint_sdwan_" . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all'));
}

1;

__END__

=head1 MODE

Check rejected packets per second by firewall.

=over 8

=item B<--warning-rejected-packets-sec>

Threshold in packets/s.

=item B<--critical-rejected-packets-sec>

Threshold in packets/s.

=back

=cut
