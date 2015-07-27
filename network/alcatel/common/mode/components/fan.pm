#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::alcatel::common::mode::components::fan;

use strict;
use warnings;
use network::alcatel::common::mode::components::resources qw(%physical_class %phys_oper_status %phys_admin_status %oids);

my @admin_conditions = (
    ['^(reset|takeover|resetWithFabric|takeoverWithFabrc)$', 'WARNING'],
    ['^(powerOff)$', 'CRITICAL'],
    ['^(?!(powerOn|standby)$)', 'UNKNOWN'],
);

my @oper_conditions = (
    ['^(testing)$', 'WARNING'],
    ['^(unpowered|down|notpresent)$', 'CRITICAL'],
    ['^(?!(up|secondary|master|idle)$)', 'UNKNOWN'],
);

my @fan_conditions = (
    ['^noStatus$', 'UNKNOWN'],
    ['^notRunning$', 'CRITICAL'],
    ['^(?!(running)$)', 'UNKNOWN'],
);

my %fan_status = (
    0 => 'noStatus',
    1 => 'notRunning',
    2 => 'running',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fan");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    my @instances = ();
    foreach my $key (keys %{$self->{results}->{$oids{entPhysicalClass}}}) {
        if ($self->{results}->{$oids{entPhysicalClass}}->{$key} == 7) {
            next if ($key !~ /^$oids{entPhysicalClass}\.(.*)$/);
            push @instances, $1;
        }
    }
    
    foreach my $instance (@instances) {
        next if (!defined($self->{results}->{$oids{chasEntPhysAdminStatus}}->{$oids{chasEntPhysAdminStatus} . '.' . $instance}));
        
        my $descr = defined($self->{results}->{$oids{entPhysicalDescr}}->{$oids{entPhysicalDescr} . '.' . $instance}) ? 
                        $self->{results}->{$oids{entPhysicalDescr}}->{$oids{entPhysicalDescr} . '.' . $instance} : 'unknown';
        my $name  = defined($self->{results}->{$oids{entPhysicalName}}->{$oids{entPhysicalName} . '.' . $instance}) ? 
                        $self->{results}->{$oids{entPhysicalName}}->{$oids{entPhysicalName} . '.' . $instance} : 'unknown';
        my $admin_status = defined($self->{results}->{$oids{chasEntPhysAdminStatus}}->{$oids{chasEntPhysAdminStatus} . '.' . $instance}) ? 
                            $self->{results}->{$oids{chasEntPhysAdminStatus}}->{$oids{chasEntPhysAdminStatus} . '.' . $instance} : 1;
        my $oper_status = defined($self->{results}->{$oids{chasEntPhysOperStatus}}->{$oids{chasEntPhysOperStatus} . '.' . $instance}) ? 
                            $self->{results}->{$oids{chasEntPhysOperStatus}}->{$oids{chasEntPhysOperStatus} . '.' . $instance} : 4;
        my $power = defined($self->{results}->{$oids{chasEntPhysPower}}->{$oids{chasEntPhysPower} . '.' . $instance}) ? 
                            $self->{results}->{$oids{chasEntPhysPower}}->{$oids{chasEntPhysPower} . '.' . $instance} : -1;
        
        next if ($self->check_exclude(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fan '%s/%s' [instance: %s, admin status: %s] operationnal status is %s.",
                                                        $name, $descr, $instance, 
                                                        $phys_admin_status{$admin_status}, $phys_oper_status{$oper_status})
                                    );
        
        my $go_forward = 1;
        foreach (@admin_conditions) {
            if ($phys_admin_status{$admin_status} =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("fan '%s/%s/%s' admin status is %s",
                                                        $name, $descr, $instance, $phys_admin_status{$admin_status}));
                $go_forward = 0;
                last;
            }
        }
        
        if ($power > 0) {
            $self->{output}->perfdata_add(label => "power_" . $instance, unit => 'W',
                                          value => $power,
                                          min => 0);
        }

        next if ($go_forward == 0);
        
        foreach (@oper_conditions) {
            if ($phys_oper_status{$oper_status} =~ /$$_[0]/i) {
                $self->{output}->output_add(severity => $$_[1],
                                            short_msg => sprintf("fan '%s/%s/%s' oeprationnal status is %s",
                                                        $name, $descr, $instance, $phys_oper_status{$oper_status}));
                last;
            }
        }
    }
    
    foreach my $key (keys %{$self->{results}->{$oids{alaChasEntPhysFanStatus}}}) {
        next if ($key !~ /^$oids{alaChasEntPhysFanStatus}\.(.*?)\.(.*?)$/);
        my ($phys_index, $loc_index) = ($1, $2);
        my $status = $self->{results}->{$oids{alaChasEntPhysFanStatus}}->{$key};
        my $descr = defined($self->{results}->{$oids{entPhysicalDescr}}->{$oids{entPhysicalDescr} . '.' . $phys_index}) ? 
                        $self->{results}->{$oids{entPhysicalDescr}}->{$oids{entPhysicalDescr} . '.' . $phys_index} : 'unknown';
        my $name  = defined($self->{results}->{$oids{entPhysicalName}}->{$oids{entPhysicalName} . '.' . $phys_index}) ? 
                        $self->{results}->{$oids{entPhysicalName}}->{$oids{entPhysicalName} . '.' . $phys_index} : 'unknown';
        
        next if ($self->check_exclude(section => 'fan', instance => $phys_index . '.' . $loc_index));
        $self->{components}->{fan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fan '%s/%s' [instance: %s] status is %s.",
                                                        $name, $descr, $loc_index, 
                                                        $fan_status{$status})
                                    );
        foreach (@fan_conditions) {
            if ($fan_status{$status} =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("fan '%s/%s/%s' status is %s.",
                                                        $name, $descr, $loc_index, 
                                                        $fan_status{$status})
                                            );
                last;
            }
        }
    }
}

1;