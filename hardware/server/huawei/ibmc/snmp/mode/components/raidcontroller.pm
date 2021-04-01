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

package hardware::server::huawei::ibmc::snmp::mode::components::raidcontroller;

use strict;
use warnings;

my $mapping = {
    raidControllerComponentName     => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.36.50.1.4' },
    raidControllerHealthStatus      => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.36.50.1.7' },
};
my $oid_raidControllerDescriptionEntry = '.1.3.6.1.4.1.2011.2.235.1.1.36.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_raidControllerDescriptionEntry,
        start => $mapping->{raidControllerComponentName}->{oid},
        end => $mapping->{raidControllerHealthStatus}->{oid},
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raid controllers");
    $self->{components}->{raidcontroller} = {name => 'raidcontrollers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'raidcontroller'));

    my %bitmap_status = (
        0 => 'memory correctable error',
        1 => 'memory uncorrectable error',
        2 => 'memory ECC error reached limit',
        3 => 'NVRAM uncorrectable error',
    );
    my %map_status = (
        0 => 'ok',
        65535 => 'unknown',
    );

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raidControllerDescriptionEntry}})) {
        next if ($oid !~ /^$mapping->{raidControllerHealthStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_raidControllerDescriptionEntry}, instance => $instance);

        next if ($self->check_filter(section => 'raidcontroller', instance => $instance));
        $self->{components}->{raidcontroller}->{total}++;
      
        if (defined($map_status{$result->{raidControllerHealthStatus}})) {
            $self->{output}->output_add(long_msg => sprintf("Raid controller '%s' status is '%s' [instance = %s]",
                                        $result->{raidControllerComponentName}, $map_status{$result->{raidControllerHealthStatus}}, $instance, 
                                        ));
   
            my $exit = $self->get_severity(section => 'raidcontroller', value => $map_status{$result->{raidControllerHealthStatus}});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Raid controller '%s' status is '%s'", $result->{raidControllerComponentName}, $map_status{$result->{raidControllerHealthStatus}}));
            }
            
            next;
        }
        
        for (my $i = 0; $i < 4; $i++) {
            next if (!($result->{raidControllerHealthStatus} & (1 << $i)));
            
            my $status = $bitmap_status{$i};
            $self->{output}->output_add(long_msg => sprintf("Raid controller '%s' status is '%s' [instance = %s]",
                                        $result->{raidControllerComponentName}, $status, $instance, 
                                        ));
   
            my $exit = $self->get_severity(section => 'raidcontroller', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Raid controller '%s' status is '%s'", $result->{raidControllerComponentName}, $status));
            }
        }
    }
}

1;
