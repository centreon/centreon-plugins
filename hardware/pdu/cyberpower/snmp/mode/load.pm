#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package hardware::pdu::cyberpower::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
}

sub device_long_output {
    my ($self, %options) = @_;

    return "checking device '" . $options{instance_value}->{display} . "'";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub prefix_bank_output {
    my ($self, %options) = @_;

    return "bank '" . $options{instance_value}->{display} . "' ";
}

sub prefix_phase_output {
    my ($self, %options) = @_;

    return "phase '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'banks', display_long => 1, cb_prefix_output => 'prefix_bank_output',  message_multiple => 'banks are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'phases', display_long => 1, cb_prefix_output => 'prefix_phase_output',  message_multiple => 'phases are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{banks} = [
        {
            label => 'bank-status',
            type => 2,
            warning_default => '%{state} =~ /low|nearOverload/i',
            critical_default => '%{state} =~ /^overload/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'bank-current', nlabel => 'bank.current.ampere', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current : %s A',
                perfdatas => [
                    { template => '%s', unit => 'A', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{phases} = [
        {
            label => 'phase-status',
            type => 2,
            warning_default => '%{state} =~ /low|nearOverload/i',
            critical_default => '%{state} =~ /^overload/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'phase-current', nlabel => 'phase.current.ampere', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current : %s A',
                perfdatas => [
                    { template => '%s', unit => 'A', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'phase-power', nlabel => 'phase.power.watt', set => {
                key_values => [ { name => 'power' } ],
                output_template => 'power : %s W',
                perfdatas => [
                    { template => '%s', unit => 'W', min => 0, label_extra_instance => 1 }
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
    });
    
    return $self;
}

my $oid_ePDUIdentName = '.1.3.6.1.4.1.3808.1.1.3.1.1';
my $oid_ePDU2DeviceConfigName = '.1.3.6.1.4.1.3808.1.1.6.3.2.1.3';

my $map_pdu_status = {
    1 => 'normal', 2 => 'low',
    3 => 'nearOverload', 4 => 'overload'
};

sub check_pdu {
    my ($self, %options) = @_;

    return if (scalar(keys %{$self->{devices}}) > 0);

    $self->{devices}->{ $options{device} } = {
        display => $options{device},
        banks => {},
        phases => {}
    };

    my $mapping = {
        current => { oid => '.1.3.6.1.4.1.3808.1.1.3.2.3.1.1.2' }, # ePDULoadStatusLoad
        state   => { oid => '.1.3.6.1.4.1.3808.1.1.3.2.3.1.1.3', map => $map_pdu_status }, # ePDULoadStatusLoadState
        phase   => { oid => '.1.3.6.1.4.1.3808.1.1.3.2.3.1.1.4' }, # ePDULoadStatusPhaseNumber
        bank    => { oid => '.1.3.6.1.4.1.3808.1.1.3.2.3.1.1.5' }, # ePDULoadStatusBankNumber [Bank 0 = no bank (phase total)]
    };

    my $oid_ePDULoadStatusEntry = '.1.3.6.1.4.1.3808.1.1.3.2.3.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ePDULoadStatusEntry,
        start => $mapping->{current}->{oid},
        end => $mapping->{bank}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{state}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $result->{current} /= 10;
        if ($result->{bank} == 0) {
            $self->{devices}->{ $options{device} }->{phases}->{ $result->{phase} } = {
                display => $result->{phase},
                %$result
            };
        } else {
            $self->{devices}->{ $options{device} }->{banks}->{ $result->{bank} } = { display => $result->{bank}, current => 0 }
                if (!defined($self->{devices}->{ $options{device} }->{banks}->{ $result->{bank} }));
            $self->{devices}->{ $options{device} }->{banks}->{ $result->{bank} }->{state} = $result->{state};
            $self->{devices}->{ $options{device} }->{banks}->{ $result->{bank} }->{current} += ($result->{current} / 10);
        }
    }
}

sub check_pdu2 {
    my ($self, %options) = @_;

    my $mapping_phase = {
        module  => { oid => '.1.3.6.1.4.1.3808.1.1.6.4.4.1.2' }, # ePDU2PhaseStatusModuleIndex
        number  => { oid => '.1.3.6.1.4.1.3808.1.1.6.4.4.1.3' }, # ePDU2PhaseStatusNumber
        state   => { oid => '.1.3.6.1.4.1.3808.1.1.6.4.4.1.4', map => $map_pdu_status }, # ePDU2PhaseStatusLoadState
        current => { oid => '.1.3.6.1.4.1.3808.1.1.6.4.4.1.5' }, # ePDU2PhaseStatusLoad
        power   => { oid => '.1.3.6.1.4.1.3808.1.1.6.4.4.1.7' } # ePDU2PhaseStatusPower
    };
    my $mapping_bank = {
        module  => { oid => '.1.3.6.1.4.1.3808.1.1.6.5.4.1.2' }, # ePDU2BankStatusModuleIndex
        number  => { oid => '.1.3.6.1.4.1.3808.1.1.6.5.4.1.3' }, # ePDU2BankStatusNumber
        state   => { oid => '.1.3.6.1.4.1.3808.1.1.6.5.4.1.4', map => $map_pdu_status }, # ePDU2BankStatusLoadState
        current => { oid => '.1.3.6.1.4.1.3808.1.1.6.5.4.1.5' } # ePDU2BankStatusLoad
    };

    my $oid_ePDU2PhaseStatusEntry = '.1.3.6.1.4.1.3808.1.1.6.4.4.1';
    my $oid_ePDU2BankStatusEntry = '.1.3.6.1.4.1.3808.1.1.6.5.4.1';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
        { oid => $oid_ePDU2PhaseStatusEntry, end => $mapping_phase->{power}->{oid} },
        { oid => $oid_ePDU2BankStatusEntry, end => $mapping_bank->{current}->{oid} }
    ]);

    foreach (keys %{$snmp_result->{$oid_ePDU2PhaseStatusEntry}}) {
        next if (! /^$mapping_phase->{state}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping_phase, results => $snmp_result->{$oid_ePDU2PhaseStatusEntry}, instance => $1);

        my $device_name = $options{devices}->{ $oid_ePDU2DeviceConfigName . '.' . $result->{module} };
        if (!defined($self->{devices}->{$device_name})) {
            $self->{devices}->{$device_name} = {
                display => $device_name,
                banks => {},
                phases => {}
            };
        }

        $self->{devices}->{$device_name}->{phases}->{ $result->{number} } = {
            display => $result->{number},
            state => $result->{state},
            current => $result->{current} / 10,
            power => $result->{power} * 10 # hundreth of kW. So * 10 for watt
        }
    }

    foreach (keys %{$snmp_result->{$oid_ePDU2BankStatusEntry}}) {
        next if (! /^$mapping_bank->{state}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping_bank, results => $snmp_result->{$oid_ePDU2BankStatusEntry}, instance => $1);

        my $device_name = $options{devices}->{ $oid_ePDU2DeviceConfigName . '.' . $result->{module} };
        if (!defined($self->{devices}->{$device_name})) {
            $self->{devices}->{$device_name} = {
                display => $device_name,
                banks => {},
                phases => {}
            };
        }

        $self->{devices}->{$device_name}->{banks}->{ $result->{number} } = {
            display => $result->{number},
            status => $result->{state},
            current => $result->{current} / 10
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_ePDUIdentName },
            { oid => $oid_ePDU2DeviceConfigName }
        ],
        nothing_quit => 1
    );

    $self->{devices} = {};
    $self->check_pdu2(snmp => $options{snmp}, devices => $snmp_result->{$oid_ePDU2DeviceConfigName});
    $self->check_pdu(
        snmp => $options{snmp},
        device => defined($snmp_result->{$oid_ePDUIdentName}->{$oid_ePDUIdentName . '.0'}) ? $snmp_result->{$oid_ePDUIdentName}->{$oid_ePDUIdentName . '.0'} : 'unknown'
    );
}

1;

__END__

=head1 MODE

Check phase/bank load.

=over 8

=item B<--unknown-bank-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--warning-bank-status>

Set warning threshold for status (Default: '%{state} =~ /low|nearOverload/i').
Can used special variables like: %{state}, %{display}

=item B<--critical-bank-status>

Set critical threshold for status (Default: '%{state} =~ /^overload/').
Can used special variables like: %{state}, %{display}

=item B<--unknown-phase-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--warning-pĥase-status>

Set warning threshold for status (Default: '%{state} =~ /low|nearOverload/i').
Can used special variables like: %{state}, %{display}

=item B<--critical-phase-status>

Set critical threshold for status (Default: '%{state} =~ /^overload/i').
Can used special variables like: %{state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'phase-current', 'phase-power', 'bank-current'.

=back

=cut
