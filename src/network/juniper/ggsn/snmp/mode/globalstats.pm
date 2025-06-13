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

package network::juniper::ggsn::snmp::mode::globalstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_drop_in_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ggsnUplinkDrops} = $options{new_datas}->{$self->{instance} . '_ggsnUplinkDrops'} - $options{old_datas}->{$self->{instance} . '_ggsnUplinkDrops'};
    $self->{result_values}->{ggsnUplinkPackets} = $options{new_datas}->{$self->{instance} . '_ggsnUplinkPackets'} - $options{old_datas}->{$self->{instance} . '_ggsnUplinkPackets'};
    if ($self->{result_values}->{ggsnUplinkPackets} == 0) {
        $self->{result_values}->{drop_prct} = 0;
    } else {
        $self->{result_values}->{drop_prct} = $self->{result_values}->{ggsnUplinkDrops} * 100 / $self->{result_values}->{ggsnUplinkPackets};
    }
    return 0;
}

sub custom_drop_out_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ggsnDownlinkDrops} = $options{new_datas}->{$self->{instance} . '_ggsnDownlinkDrops'} - $options{old_datas}->{$self->{instance} . '_ggsnDownlinkDrops'};
    $self->{result_values}->{ggsnDownlinkPackets} = $options{new_datas}->{$self->{instance} . '_ggsnDownlinkPackets'} - $options{old_datas}->{$self->{instance} . '_ggsnDownlinkPackets'};
    if ($self->{result_values}->{ggsnDownlinkPackets} == 0) {
        $self->{result_values}->{drop_prct} = 0;
    } else {
        $self->{result_values}->{drop_prct} = $self->{result_values}->{ggsnDownlinkDrops} * 100 / $self->{result_values}->{ggsnDownlinkPackets};
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'traffic-in', set => {
                key_values => [ { name => 'ggsnUplinkBytes', per_second => 1 } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%s', unit => 'b/s', min => 0, cast_int => 1 },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'ggsnDownlinkBytes', per_second => 1 } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%s', unit => 'b/s', min => 0, cast_int => 1 },
                ],
            }
        },
        { label => 'drop-in', set => {
                key_values => [ { name => 'ggsnUplinkDrops', diff => 1 }, { name => 'ggsnUplinkPackets', diff => 1 } ],
                output_template => 'Drop In Packets : %.2f %%', threshold_use => 'drop_prct', output_use => 'drop_prct',
                closure_custom_calc => \&custom_drop_in_calc,
                perfdatas => [
                    { label => 'drop_in', value => 'ggsnUplinkDrops', template => '%s',
                      min => 0, max => 'ggsnUplinkPackets' },
                ],
            }
        },
        { label => 'drop-out', set => {
                key_values => [ { name => 'ggsnDownlinkDrops', diff => 1 }, { name => 'ggsnDownlinkPackets', diff => 1 } ],
                output_template => 'Drop Out Packets : %.2f %%', threshold_use => 'drop_prct', output_use => 'drop_prct',
                closure_custom_calc => \&custom_drop_out_calc,
                perfdatas => [
                    { label => 'drop_out', value => 'ggsnDownlinkDrops', template => '%s',
                      min => 0, max => 'ggsnDownlinkPackets' },
                ],
            }
        },
        { label => 'active-pdp', set => {
                key_values => [ { name => 'ggsnNbrOfActivePdpContexts' } ],
                output_template => 'Active Pdp : %s',
                perfdatas => [
                    { label => 'active_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'attempted-activation-pdp', set => {
                key_values => [ { name => 'ggsnAttemptedActivation', diff => 1 } ],
                output_template => 'Attempted Activation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_activation_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'attempted-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnAttemptedDeactivation', diff => 1 } ],
                output_template => 'Attempted Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_deactivation_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'attempted-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnAttemptedDeactivation', diff => 1 } ],
                output_template => 'Attempted Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_deactivation_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'attempted-self-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnAttemptedSelfDeactivation', diff => 1 } ],
                output_template => 'Attempted Self Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_self_deactivation_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'attempted-update-pdp', set => {
                key_values => [ { name => 'ggsnAttemptedUpdate', diff => 1 } ],
                output_template => 'Attempted Update Pdp : %s',
                perfdatas => [
                    { label => 'attempted_update_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'completed-activation-pdp', set => {
                key_values => [ { name => 'ggsnCompletedActivation', diff => 1 } ],
                output_template => 'Completed Activation Pdp : %s',
                perfdatas => [
                    { label => 'completed_activation_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'completed-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnCompletedDeactivation', diff => 1 } ],
                output_template => 'Completed Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'completed_deactivation_pdp', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'completed-self-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnCompletedSelfDeactivation', diff => 1 } ],
                output_template => 'Completed Self Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'completed_self_deactivation_pdp', emplate => '%s', min => 0 },
                ],
            }
        },
        { label => 'completed-update-pdp', set => {
                key_values => [ { name => 'ggsnCompletedUpdate', diff => 1 } ],
                output_template => 'Completed Update Pdp : %s',
                perfdatas => [
                    { label => 'completed_update_pdp', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Global Stats ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    ggsnNbrOfActivePdpContexts      => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.2' },
    ggsnAttemptedActivation         => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.1' },
    ggsnAttemptedDeactivation       => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.2' },
    ggsnAttemptedSelfDeactivation   => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.3' },
    ggsnAttemptedUpdate             => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.3.4' },
    ggsnCompletedActivation         => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.1' },
    ggsnCompletedDeactivation       => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.2' },
    ggsnCompletedSelfDeactivation   => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.3' },
    ggsnCompletedUpdate             => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.4.4' },
    ggsnUplinkPackets               => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.11.1' },
    ggsnUplinkBytes                 => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.11.2' },
    ggsnUplinkDrops                 => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.11.3' },
    ggsnDownlinkPackets             => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.12.1' },
    ggsnDownlinkBytes               => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.12.2' },
    ggsnDownlinkDrops               => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.3.12.3' },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }    

    my $oid_ggsnGlobalStats = '.1.3.6.1.4.1.10923.1.1.1.1.1.3';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ggsnGlobalStats,
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->{global}->{ggsnDownlinkBytes} *= 8 if (defined($self->{global}->{ggsnDownlinkBytes}));
    $self->{global}->{ggsnUplinkBytes} *= 8 if (defined($self->{global}->{ggsnUplinkBytes}));

    $self->{cache_name} = "juniper_ggsn_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check global statistics.

=over 8

=item B<--warning-traffic-in>

Warning threshold for traffic in (in bps).

=item B<--critical-traffic-in>

Critical threshold for traffic in (in bps).

=item B<--warning-traffic-out>

Warning threshold for traffic out (in bps).

=item B<--critical-traffic-out>

Critical threshold for traffic out (in bps).

=item B<--warning-drop-in>

Warning threshold for drop in packets (in %).

=item B<--critical-drop-in>

Critical threshold for drop in packets (in %).

=item B<--warning-drop-out>

Warning threshold for drop out packets (in %).

=item B<--critical-drop-out>

Critical threshold for drop out packets (in %).

=item B<--warning-active-pdp>

Warning threshold for active Packet Data Protocol contexts.

=item B<--critical-active-pdp>

Critical threshold for active Packet Data Protocol contexts.

=item B--warning-attempted-activation-pdp>

Warning threshold for attempted activation of Packet Data Protocol contexts.

=item B<--critical-attempted-activation-pdp>

Critical threshold for attempted activation of Packet Data Protocol contexts.

=item B<--warning-attempted-update-pdp>

Warning threshold for attempted update of Packet Data Protocol contexts.

=item B<--critical-attempted-update-pdp>

Critical threshold for attempted update of Packet Data Protocol contexts.

=item B<--warning-attempted-deactivation-pdp>

Warning threshold for attempted deactivation of Packet Data Protocol contexts.

=item B<--critical-attempted-deactivation-pdp>

Critical threshold for attempted deactivation of Packet Data Protocol contexts.

=item B<--warning-attempted-self-deactivation-pdp>

Warning threshold for attempted self-deactivation of Packet Data Protocol contexts.

=item B<--critical-attempted-self-deactivation-pdp>

Critical threshold for attempted self-deactivation of Packet Data Protocol contexts.

=item B<--warning-completed-activation-pdp>

Warning threshold for completed activation of Packet Data Protocol contexts.

=item B<--critical-completed-activation-pdp>

Critical threshold for completed activation of Packet Data Protocol contexts.

=item B<--warning-completed-update-pdp>

Warning threshold for completed update of Packet Data Protocol contexts.

=item B<--critical-completed-update-pdp>

Critical threshold for completed update of Packet Data Protocol contexts.

=item B<--warning-completed-deactivation-pdp>

Warning threshold for completed deactivation of Packet Data Protocol contexts.

=item B<--critical-completed-deactivation-pdp>

Critical threshold for completed deactivation of Packet Data Protocol contexts.

=item B<--warning-completed-self-deactivation-pdp>

Warning threshold for completed self-deactivation of Packet Data Protocol contexts.

=item B<--critical-completed-self-deactivation-pdp>

Critical threshold for completed self-deactivation of Packet Data Protocol contexts.

=back

=cut
