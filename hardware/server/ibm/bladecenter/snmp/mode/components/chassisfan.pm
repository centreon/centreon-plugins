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

package hardware::server::ibm::bladecenter::snmp::mode::components::chassisfan;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown', 
    1 => 'good', 
    2 => 'warning', 
    3 => 'bad',
);

# In MIB 'mmblade.mib' and 'cme.mib'
my $mapping = {
    chassisFanState => { oid => '.1.3.6.1.4.1.2.3.51.2.2.3.50.1.4', map => \%map_state },
    chassisFanSpeedRPM => { oid => '.1.3.6.1.4.1.2.3.51.2.2.3.50.1.5' },
};
my $oid_chassisFansEntry = '.1.3.6.1.4.1.2.3.51.2.2.3.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_chassisFansEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking chassis fan");
    $self->{components}->{chassisfan} = {name => 'chassis fan', total => 0, skip => 0};
    return if ($self->check_filter(section => 'chassisfan'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_chassisFansEntry}})) {
        next if ($oid !~ /^$mapping->{chassisFanState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_chassisFansEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'chassisfan', instance => $instance));
        $self->{components}->{chassisfan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Chassis fan '%s' is %s rpm [status: %s, instance: %s]", 
                                    $instance, $result->{chassisFanSpeedRPM}, $result->{chassisFanState},
                                    $instance));
        my $exit = $self->get_severity(section => 'chassisfan', value => $result->{chassisFanState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Chassis fan '%s' status is %s", 
                                            $instance, $result->{chassisFanState}));
        }
        
        if (defined($result->{chassisFanSpeedRPM}) && $result->{chassisFanSpeedRPM} =~ /[0-9]/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'chassisfan', instance => $instance, value => $result->{chassisFanSpeedRPM});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Chassis fan '%s' speed is %s rpm", $instance, $result->{chassisFanSpeedRPM}));
            }
            $self->{output}->perfdata_add(
                label => "chassisfan", unit => 'rpm',
                nlabel => 'hardware.chassis.fan.speed.rpm',
                instances => $instance,
                value => $result->{chassisFanSpeedRPM},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
