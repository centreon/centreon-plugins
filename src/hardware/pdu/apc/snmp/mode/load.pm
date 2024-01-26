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

package hardware::pdu::apc::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_bank_output {
    my ($self, %options) = @_;

    return "Bank '" . $options{instance_value}->{display} . "' ";
}

sub prefix_phase_output {
    my ($self, %options) = @_;

    return "Phase '" . $options{instance_value}->{display} . "' ";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'device', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok', skipped_code => { -10 => 1 } },
        { name => 'bank', type => 1, cb_prefix_output => 'prefix_bank_output', message_multiple => 'All banks are ok', skipped_code => { -10 => 1 } },
        { name => 'phase', type => 1, cb_prefix_output => 'prefix_phase_output', message_multiple => 'All phases are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{bank} = [
        {
            label => 'bank-status',
            type => 2,
            warning_default => '%{status} =~ /low|nearOverload/i',
            critical_default => '%{status} =~ /^overload/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current', nlabel => 'bank.current.ampere', set => {
                key_values => [ { name => 'current' }, { name => 'display' } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { template => '%s', unit => 'A', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{phase} = [
        {
            label => 'phase-status',
            type => 2,
            warning_default => '%{status} =~ /low|nearOverload/i',
            critical_default => '%{status} =~ /^overload/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current', nlabel => 'phase.current.ampere', set => {
                key_values => [ { name => 'current' }, { name => 'display' } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { template => '%s', unit => 'A', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'power', nlabel => 'phase.power.watt', set => {
                key_values => [ { name => 'power' }, { name => 'display' } ],
                output_template => 'power: %s W',
                perfdatas => [
                    { template => '%s', unit => 'W', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device} = [
        { label => 'power', nlabel => 'device.power.watt', set => {
                key_values => [ { name => 'power' }, { name => 'display' } ],
                output_template => 'power: %s W',
                perfdatas => [
                    { template => '%s', unit => 'W', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

my $map_rpdu_status = {
    1 => 'normal',
    2 => 'low',
    3 => 'nearOverload',
    4 => 'overload',
};

sub check_rpdu {
    my ($self, %options) = @_;

    return if (scalar(keys %{$self->{phase}}) > 0);

    my $mapping = {
        rPDULoadStatusLoad          => { oid => '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.2' },
        rPDULoadStatusLoadState     => { oid => '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.3', map => $map_rpdu_status },
        rPDULoadStatusPhaseNumber   => { oid => '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.4' }, 
        rPDULoadStatusBankNumber    => { oid => '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.5' } # Bank 0 = no bank (phase total)
    };

    my $oid_rPDULoadStatusEntry = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_rPDULoadStatusEntry, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{rPDULoadStatusLoadState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if ($result->{rPDULoadStatusBankNumber} == 0) {
            $self->{phase}->{$result->{rPDULoadStatusPhaseNumber}} = {
                display => $result->{rPDULoadStatusPhaseNumber},
                status => $result->{rPDULoadStatusLoadState},
                current => $result->{rPDULoadStatusLoad} / 10
            };
        } else {
            $self->{bank}->{$result->{rPDULoadStatusBankNumber}} = { display => $result->{rPDULoadStatusBankNumber}, current => 0 }
                if (!defined($self->{bank}->{$result->{rPDULoadStatusBankNumber}}));
            $self->{bank}->{$result->{rPDULoadStatusBankNumber}}->{status} = $result->{rPDULoadStatusLoadState};
            $self->{bank}->{$result->{rPDULoadStatusBankNumber}}->{current} += $result->{rPDULoadStatusLoad} / 10;
        }
    }

    my $oid_rPDUIdentName = '.1.3.6.1.4.1.318.1.1.12.1.1.0';
    my $oid_rPDUIdentDevicePowerWatts = '.1.3.6.1.4.1.318.1.1.12.1.16.0';
    $snmp_result = $options{snmp}->get_leef(oids => [$oid_rPDUIdentName, $oid_rPDUIdentDevicePowerWatts]);
    $self->{device}->{0} = {
        display => $snmp_result->{$oid_rPDUIdentName},
        power => $snmp_result->{$oid_rPDUIdentDevicePowerWatts}
    };
}

my $map_rpdu2_status = {
    1 => 'low',
    2 => 'normal',
    3 => 'nearOverload',
    4 => 'overload',
};

sub check_rpdu2 {
    my ($self, %options) = @_;

    my $mapping_phase = {
        rPDU2PhaseStatusModule    => { oid => '.1.3.6.1.4.1.318.1.1.26.6.3.1.2' },
        rPDU2PhaseStatusNumber    => { oid => '.1.3.6.1.4.1.318.1.1.26.6.3.1.3' },
        rPDU2PhaseStatusLoadState => { oid => '.1.3.6.1.4.1.318.1.1.26.6.3.1.4', map => $map_rpdu2_status },
        rPDU2PhaseStatusCurrent   => { oid => '.1.3.6.1.4.1.318.1.1.26.6.3.1.5' }, 
        rPDU2PhaseStatusPower     => { oid => '.1.3.6.1.4.1.318.1.1.26.6.3.1.7' }
    };
    my $mapping_bank = {
        rPDU2BankStatusModule     => { oid => '.1.3.6.1.4.1.318.1.1.26.8.3.1.2' },
        rPDU2BankStatusNumber     => { oid => '.1.3.6.1.4.1.318.1.1.26.8.3.1.3' },
        rPDU2BankStatusLoadState  => { oid => '.1.3.6.1.4.1.318.1.1.26.8.3.1.4', map => $map_rpdu2_status },
        rPDU2BankStatusCurrent    => { oid => '.1.3.6.1.4.1.318.1.1.26.8.3.1.5' }
    };
    my $mapping_device = {
        rPDU2DeviceStatusName     => { oid => '.1.3.6.1.4.1.318.1.1.26.4.3.1.3' },
        rPDU2DeviceStatusPower    => { oid => '.1.3.6.1.4.1.318.1.1.26.4.3.1.5' }
    };

    my $oid_rPDU2DeviceStatusEntry = '.1.3.6.1.4.1.318.1.1.26.4.3.1';
    my $oid_rPDU2PhaseStatusEntry = '.1.3.6.1.4.1.318.1.1.26.6.3.1';
    my $oid_rPDU2BankStatusEntry = '.1.3.6.1.4.1.318.1.1.26.8.3.1';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
        { oid => $oid_rPDU2PhaseStatusEntry, end => $mapping_phase->{rPDU2PhaseStatusPower}->{oid} },
        { oid => $oid_rPDU2BankStatusEntry, end => $mapping_bank->{rPDU2BankStatusCurrent}->{oid} },
        { oid => $oid_rPDU2DeviceStatusEntry, end => $mapping_device->{rPDU2DeviceStatusPower}->{oid} }
    ]);

    foreach my $oid (keys %{$snmp_result->{$oid_rPDU2PhaseStatusEntry}}) {
        next if ($oid !~ /^$mapping_phase->{rPDU2PhaseStatusLoadState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_phase, results => $snmp_result->{$oid_rPDU2PhaseStatusEntry}, instance => $instance);

        my $name = 'mod' . $result->{rPDU2PhaseStatusModule} . 'phase' . $result->{rPDU2PhaseStatusNumber};
        $self->{phase}->{$name} = {
            display => $name,
            status => $result->{rPDU2PhaseStatusLoadState},
            current => $result->{rPDU2PhaseStatusCurrent} / 10,
            power => defined($result->{rPDU2PhaseStatusPower}) ? $result->{rPDU2PhaseStatusPower} * 10 : undef # hundreth of kW. So * 10 for watt
        }
    }

    foreach my $oid (keys %{$snmp_result->{$oid_rPDU2BankStatusEntry}}) {
        next if ($oid !~ /^$mapping_bank->{rPDU2BankStatusLoadState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_bank, results => $snmp_result->{$oid_rPDU2BankStatusEntry}, instance => $instance);

        my $name = 'mod' . $result->{rPDU2BankStatusModule} . 'bank' . $result->{rPDU2BankStatusNumber};
        $self->{bank}->{$name} = {
            display => $name,
            status => $result->{rPDU2BankStatusLoadState},
            current => $result->{rPDU2BankStatusCurrent} / 10
        }
    }

    foreach my $oid (keys %{$snmp_result->{$oid_rPDU2DeviceStatusEntry}}) {
        next if ($oid !~ /^$mapping_device->{rPDU2DeviceStatusName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_device, results => $snmp_result->{$oid_rPDU2DeviceStatusEntry}, instance => $instance);

        $self->{device}->{$result->{rPDU2DeviceStatusName}} = {
            display => $result->{rPDU2DeviceStatusName},
            power => defined($result->{rPDU2DeviceStatusPower}) ? $result->{rPDU2DeviceStatusPower} * 10 : undef
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{bank} = {};
    $self->{phase} = {};
    $self->{device} = {};
    
    $self->check_rpdu2(%options);
    $self->check_rpdu(%options);
    
    if (scalar(keys %{$self->{device}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No device found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check phase/bank load.

=over 8

=item B<--unknown-bank-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{type}, %{status}, %{display}

=item B<--warning-bank-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /low|nearOverload/i').
You can use the following variables: %{type}, %{status}, %{display}

=item B<--critical-bank-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /^overload/').
You can use the following variables: %{type}, %{status}, %{display}

=item B<--unknown-phase-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{display}

=item B<--warning-phase-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /low|nearOverload/i').
You can use the following variables: %{status}, %{display}

=item B<--critical-phase-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /^overload/i').
You can use the following variables: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'current', 'power'.

=back

=cut
