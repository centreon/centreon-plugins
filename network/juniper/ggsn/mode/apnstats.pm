#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package network::juniper::ggsn::mode::apnstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_drop_in_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ggsnApnName} = $options{new_datas}->{$self->{instance} . '_ggsnApnName'};
    $self->{result_values}->{ggsnApnUplinkDrops} = $options{new_datas}->{$self->{instance} . '_ggsnApnUplinkDrops'} - $options{old_datas}->{$self->{instance} . '_ggsnApnUplinkDrops'};
    $self->{result_values}->{ggsnApnUplinkPackets} = $options{new_datas}->{$self->{instance} . '_ggsnApnUplinkPackets'} - $options{old_datas}->{$self->{instance} . '_ggsnApnUplinkPackets'};
    if ($self->{result_values}->{ggsnApnUplinkPackets} == 0) {
        $self->{result_values}->{drop_prct} = 0;
    } else {
        $self->{result_values}->{drop_prct} = $self->{result_values}->{ggsnApnUplinkDrops} * 100 / $self->{result_values}->{ggsnApnUplinkPackets};
    }
    return 0;
}

sub custom_drop_out_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ggsnApnName} = $options{new_datas}->{$self->{instance} . '_ggsnApnName'};
    $self->{result_values}->{ggsnApnDownlinkDrops} = $options{new_datas}->{$self->{instance} . '_ggsnApnDownlinkDrops'} - $options{old_datas}->{$self->{instance} . '_ggsnApnDownlinkDrops'};
    $self->{result_values}->{ggsnApnDownlinkPackets} = $options{new_datas}->{$self->{instance} . '_ggsnApnDownlinkPackets'} - $options{old_datas}->{$self->{instance} . '_ggsnApnDownlinkPackets'};
    if ($self->{result_values}->{ggsnApnDownlinkPackets} == 0) {
        $self->{result_values}->{drop_prct} = 0;
    } else {
        $self->{result_values}->{drop_prct} = $self->{result_values}->{ggsnApnDownlinkDrops} * 100 / $self->{result_values}->{ggsnApnDownlinkPackets};
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'apn', type => 1, cb_prefix_output => 'prefix_apn_output', message_multiple => 'All apn statistics are ok' }
    ];
    
    $self->{maps_counters}->{apn} = [
        { label => 'traffic-in', set => {
                key_values => [ { name => 'ggsnApnUplinkBytes', per_second => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%s',
                      unit => 'b/s', min => 0, label_extra_instance => 1, cast_int => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'ggsnApnDownlinkBytes', per_second => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%s',
                      unit => 'b/s', min => 0, label_extra_instance => 1, cast_int => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'drop-in', set => {
                key_values => [ { name => 'ggsnApnUplinkDrops', diff => 1 }, { name => 'ggsnApnUplinkPackets', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Drop In Packets : %.2f %%', threshold_use => 'drop_prct', output_use => 'drop_prct',
                closure_custom_calc => $self->can('custom_drop_in_calc'),
                perfdatas => [
                    { label => 'drop_in', value => 'ggsnApnUplinkDrops', template => '%s',
                      min => 0, max => 'ggsnApnUplinkPackets', label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'drop-out', set => {
                key_values => [ { name => 'ggsnApnDownlinkDrops', diff => 1 }, { name => 'ggsnApnDownlinkPackets', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Drop Out Packets : %.2f %%', threshold_use => 'drop_prct', output_use => 'drop_prct',
                closure_custom_calc => $self->can('custom_drop_out_calc'),
                perfdatas => [
                    { label => 'drop_out', value => 'ggsnApnDownlinkDrops', template => '%s',
                      min => 0, max => 'ggsnApnDownlinkPackets', label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'active-pdp', set => {
                key_values => [ { name => 'ggsnApnActivePdpContextCount' }, { name => 'ggsnApnName' } ],
                output_template => 'Active Pdp : %s',
                perfdatas => [
                    { label => 'active_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'attempted-activation-pdp', set => {
                key_values => [ { name => 'ggsnApnAttemptedActivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Attempted Activation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_activation_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'attempted-dyn-activation-pdp', set => {
                key_values => [ { name => 'ggsnApnAttemptedDynActivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Attempted Dyn Activation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_dyn_activation_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'attempted-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnApnAttemptedDeactivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Attempted Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_deactivation_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'attempted-self-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnApnAttemptedSelfDeactivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Attempted Self Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'attempted_self_deactivation_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'completed-activation-pdp', set => {
                key_values => [ { name => 'ggsnApnCompletedActivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Completed Activation Pdp : %s',
                perfdatas => [
                    { label => 'completed_activation_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'completed-dyn-activation-pdp', set => {
                key_values => [ { name => 'ggsnApnCompletedDynActivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Completed Dyn Activation Pdp : %s',
                perfdatas => [
                    { label => 'completed_dyn_activation_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'completed-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnApnCompletedDeactivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Completed Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'completed_deactivation_pdp', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
        { label => 'completed-self-deactivation-pdp', set => {
                key_values => [ { name => 'ggsnApnCompletedSelfDeactivation', diff => 1 }, { name => 'ggsnApnName' } ],
                output_template => 'Completed Self Deactivation Pdp : %s',
                perfdatas => [
                    { label => 'completed_self_deactivation_pdp',  template => '%s', min => 0, label_extra_instance => 1, instance_use => 'ggsnApnName' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub prefix_apn_output {
    my ($self, %options) = @_;
    
    return "APN '" . $options{instance_value}->{ggsnApnName} . "' ";
}

my $mapping = {
    ggsnApnName                         => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.2' },
    ggsnApnActivePdpContextCount        => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.3' },
    ggsnApnAttemptedActivation          => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.4' },
    ggsnApnAttemptedDynActivation       => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.5' },
    ggsnApnAttemptedDeactivation        => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.6' },
    ggsnApnAttemptedSelfDeactivation    => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.7' },
    ggsnApnCompletedActivation          => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.8' },
    ggsnApnCompletedDynActivation       => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.9' },
    ggsnApnCompletedDeactivation        => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.10' },
    ggsnApnCompletedSelfDeactivation    => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.11' },
    ggsnApnUplinkPackets                => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.12' },
    ggsnApnUplinkBytes                  => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.13' },
    ggsnApnUplinkDrops                  => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.14' },
    ggsnApnDownlinkPackets              => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.15' },
    ggsnApnDownlinkBytes                => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.16' },
    ggsnApnDownlinkDrops                => { oid => '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1.17' },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    $self->{apn} = {};
    my $oid_ggsnApnStatsEntry = '.1.3.6.1.4.1.10923.1.1.1.1.1.5.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ggsnApnStatsEntry,
        nothing_quit => 1
    );
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ggsnApnName}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ggsnApnName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{ggsnApnName} . "': no matching filter.");
            next;
        }
        
        $result->{ggsnApnDownlinkBytes} *= 8 if (defined($result->{ggsnApnDownlinkBytes}));
        $result->{ggsnApnUplinkBytes} *= 8 if (defined($result->{ggsnApnUplinkBytes}));
        $self->{apn}->{$instance} = $result;
    }
    
    if (scalar(keys %{$self->{apn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "juniper_ggsn_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check APN statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in' (bps), 'traffic-out' (bps), 'drop-in' (%), 'drop-out' (%), 
'active-pdp', 'attempted-activation-pdp', 'attempted-dyn-activation-pdp', 'attempted-deactivation-pdp',
'attempted-self-deactivation-pdp', 'completed-activation-pdp', 'completed-dyn-activation-pdp',
'completed-deactivation-pdp', 'completed-self-deactivation-pdp'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in' (bps), 'traffic-out' (bps), 'drop-in' (%), 'drop-out' (%), 
'active-pdp', 'attempted-activation-pdp', 'attempted-dyn-activation-pdp', 'attempted-deactivation-pdp',
'attempted-self-deactivation-pdp', 'completed-activation-pdp', 'completed-dyn-activation-pdp',
'completed-deactivation-pdp', 'completed-self-deactivation-pdp'.

=item B<--filter-name>

Filter APN name (can be a regexp).

=back

=cut
