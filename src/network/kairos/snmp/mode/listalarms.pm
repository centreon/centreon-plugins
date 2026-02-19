#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::kairos::snmp::mode::listalarms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my @mapping = ('name', 'instance');

sub manage_selection {
    my ($self, %options) = @_;

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

    my $oid_alarmTable = '.1.3.6.1.4.1.37755.51';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_alarmTable);
    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_alarmTable\.(\d+)\.\d+$/);
        my $instance = $1;
        next if ($snmp_result->{$oid} !~ /^Alarm\s+.*?\s+->\s+Tot:\d+/i);
        my $name = $map_name{$instance};

        $results->{$instance} = {
            instance => $instance,
            name => $name
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $instance (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_: " . $results->{$instance}->{$_} . ']', @mapping))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List alarms:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => \@mapping);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {        
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}
1;

__END__

=head1 MODE

List alarms.

=over 8

=back

=cut
