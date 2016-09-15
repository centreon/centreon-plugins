#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::radware::alteon::common::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states_temp_cpu = (
    1 => ['normal', 'OK'], 
    2 => ['warning', 'WARNING'],
    3 => ['critical', 'CRITICAL'],     
);
my %states_temp = (
    1 => ['ok', 'OK'], 
    2 => ['exceed', 'WARNING'], 
);
my %states_psu = (
    1 => ['single power supply ok', 'WARNING'], 
    2 => ['first powerSupply failed', 'CRITICAL'],
    3 => ['second power supply failed', 'CRITICAL'],
    4 => ['double power supply ok', 'OK'],
    5 => ['unknown power supply failed', 'UNKNOWN'],
);
my %states_fan = (
    1 => ['ok', 'OK'], 
    2 => ['fail', 'CRITICAL'],
);
my $oid_hwTemperatureStatus = '.1.3.6.1.4.1.1872.2.5.1.3.1.3.0';
my $oid_hwFanStatus = '.1.3.6.1.4.1.1872.2.5.1.3.1.4.0';
my $oid_hwTemperatureThresholdStatusCPU1Get = '.1.3.6.1.4.1.1872.2.5.1.3.1.28.3.0';
my $oid_hwTemperatureThresholdStatusCPU2Get = '.1.3.6.1.4.1.1872.2.5.1.3.1.28.4.0';
my $oid_hwPowerSupplyStatus = '.1.3.6.1.4.1.1872.2.5.1.3.1.29.2.0';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->{components_fans} = 0;
    $self->{components_psus} = 0;
    $self->{components_temperatures} = 0;
    
    $self->{global_result} = $self->{snmp}->get_leef(oids => [$oid_hwTemperatureStatus, $oid_hwFanStatus, 
                                                     $oid_hwTemperatureThresholdStatusCPU1Get, $oid_hwTemperatureThresholdStatusCPU2Get,
                                                     $oid_hwPowerSupplyStatus],
                                                     nothing_quit => 1);
    
    $self->check_fans();
    $self->check_psus();
    $self->check_temperatures();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %d components [%d fans, %d power supplies, %d temperatures] are ok", 
                                ($self->{components_fans} + $self->{components_psus} + $self->{components_temperatures}), 
                                $self->{components_fans}, $self->{components_psus}, $self->{components_temperatures}));
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub check_fans {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    return if (!defined($self->{global_result}->{$oid_hwFanStatus}));
    
    $self->{components_fans}++;
    my $fan_state = $self->{global_result}->{$oid_hwFanStatus};
  
    $self->{output}->output_add(long_msg => sprintf("Fan status is %s.", ${$states_fan{$fan_state}}[0]));
    if (${$states_fan{$fan_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states_fan{$fan_state}}[1],
                                    short_msg => sprintf("Fan status is %s.", ${$states_fan{$fan_state}}[0]));
    }
}

sub check_psus {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    return if (!defined($self->{global_result}->{$oid_hwPowerSupplyStatus}));
    
    $self->{components_psus}++;
    my $psu_state = $self->{global_result}->{$oid_hwPowerSupplyStatus};
  
    $self->{output}->output_add(long_msg => sprintf("Power supplies status is %s.", ${$states_psu{$psu_state}}[0]));
    if (${$states_psu{$psu_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states_psu{$psu_state}}[1],
                                    short_msg => sprintf("Power supplies status is %s.", ${$states_psu{$psu_state}}[0]));
    }
}

sub check_temperatures {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures global");
    return if (!defined($self->{global_result}->{$oid_hwTemperatureStatus}));
    
    $self->{components_temperatures}++;
    my $temp_state = $self->{global_result}->{$oid_hwTemperatureStatus};
  
    $self->{output}->output_add(long_msg => sprintf("Global temperature sensor status is %s.", ${$states_temp{$temp_state}}[0]));
    if (${$states_temp{$temp_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states_temp{$temp_state}}[1],
                                    short_msg => sprintf("Global temperature sensor  status is %s.", ${$states_temp{$temp_state}}[0]));
    }
    
    $self->{output}->output_add(long_msg => "Checking temperatures cpus");
    return if (!defined($self->{global_result}->{$oid_hwTemperatureThresholdStatusCPU1Get}) && 
               !defined($self->{global_result}->{$oid_hwTemperatureThresholdStatusCPU2Get}));
    
    $self->{components_temperatures} += 2;
    my $temp_cpu1_state = $self->{global_result}->{$oid_hwTemperatureThresholdStatusCPU1Get};
    my $temp_cpu2_state = $self->{global_result}->{$oid_hwTemperatureThresholdStatusCPU2Get};
  
    $self->{output}->output_add(long_msg => sprintf("Temperature cpu 1 status is %s.", ${$states_temp_cpu{$temp_cpu1_state}}[0]));
    if (${$states_temp_cpu{$temp_cpu1_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states_temp_cpu{$temp_cpu1_state}}[1],
                                    short_msg => sprintf("Temperature cpu 1 status is %s.", ${$states_temp_cpu{$temp_cpu1_state}}[0]));
    }
    
    $self->{output}->output_add(long_msg => sprintf("Temperature cpu 2 status is %s.", ${$states_temp_cpu{$temp_cpu2_state}}[0]));
    if (${$states_temp_cpu{$temp_cpu2_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states_temp_cpu{$temp_cpu2_state}}[1],
                                    short_msg => sprintf("Temperature cpu 2 status is %s.", ${$states_temp_cpu{$temp_cpu2_state}}[0]));
    }
}

1;

__END__

=head1 MODE

Check Hardware (ALTEON-CHEETAH-SWITCH-MIB) (Fans, Power Supplies, Temperatures).

=over 8

=back

=cut
    