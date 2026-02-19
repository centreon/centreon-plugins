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

package network::kairos::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "alarm '%s' count: %d [%s]",
        $self->{result_values}->{description},
        $self->{result_values}->{count},
        $self->{result_values}->{name}
    );
}

sub custom_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'alarm.' . $self->{result_values}->{name} . '.count',
        value => $self->{result_values}->{count},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'alarms', type => 1, message_multiple => 'All alarms are ok' }
    ];

    $self->{maps_counters}->{alarms} = [
        { label => 'count', set => {
                key_values => [ { name => 'name' }, { name => 'description' }, { name => 'count', diff => 1 } ],
                closure_custom_output => $self->can('custom_output'),
                threshold_use => 'count',
                closure_custom_perfdata => $self->can('custom_perfdata'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-instance:s' => { name => 'filter_instance' },
        'filter-name:s'     => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "kairos_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{filter_instance}) ? $self->{option_results}->{filter_instance} : '')
        );

    my %map_name = (
        1 => 'IO1Contact',
        2 => 'IO2Contact',
        3 => 'LogicSupply',
        4 => 'SupplyHigh',
        5 => 'SupplyLow',
        6 => 'EthLink',
        7 => 'PldData',
        8 => 'DspUpAndRun',
        9 => 'Gnss',
        10 => 'Vocoder',
        11 => 'BsTemperature',
        12 => 'TxTemperature',
        13 => 'NoTxPower',
        14 => 'TxPowerLow',
        15 => 'TxPowerHigh',
        16 => 'SWRPower',
        17 => 'ROS',
        18 => 'TxPowerReduced',
        19 => 'SynchSource',
        20 => 'Synch',
        21 => 'BoardVTunes',
        22 => 'TrxVTunes',
        23 => 'BoardClock',
        24 => 'TrxClock',
        25 => 'BoardPllLock',
        26 => 'TrxPllLock',
        27 => 'PldFault',
        28 => 'PldDspComm',
        29 => 'IFRxGen',
        30 => 'RxGen',
        31 => 'RfNoise',
        32 => 'RegMaster',
        33 => 'RegSlave',
        34 => 'DeregSlave',
        35 => 'LossSlave',
        36 => 'MasterRole',
        37 => 'BckMasterConn',
        38 => 'DmrEmerCall',
        39 => '1Plus1BsActive',
        40 => '1Plus1BsHotSpare',
        41 => 'TrxLayer',
        42 => 'BsLayer',
        43 => 'SipNameResolve',
        44 => 'FailSipReg',
        45 => 'SipReg',
        46 => 'SipDereg',
        47 => 'SipServerChange',
        48 => 'SipTrunk'
    );

    $self->{alarms} = {};

    my $oid_alarmTable = '.1.3.6.1.4.1.37755.51';

    my $snmp_result = $options{snmp}->get_table(oid => $oid_alarmTable, nothing_quit => 1);
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_alarmTable\.(\d+)\.\d+$/);
        my $instance = $1;
        next if ($snmp_result->{$oid} !~ /^Alarm\s+(.*?)\s+->\s+Tot:(\d+)/i);
        my ($name, $description, $count) = ($map_name{$instance}, $1, $2);

        next if (defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne '' &&
            $instance ne /$self->{option_results}->{filter_instance}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{alarms}->{$instance} = {
            instance => $instance,
            name => $name,
            description => $description,
            count => $count
        };
    }
}

1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--filter-instance>

Filter on alarm instance (Can be a regexp).

=item B<--filter-name>

Filter on alarm name (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'count'.

=back

=cut
