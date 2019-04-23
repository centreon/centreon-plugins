#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::citrix::netscaler::snmp::mode::components::fanspeed;

use strict;
use warnings;

my $mapping = {
    sysHealthCounterName    => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.7.1.1' },
    sysHealthCounterValue   => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.7.1.2' },
};
my $oid_nsSysHealthEntry = '.1.3.6.1.4.1.5951.4.1.1.41.7.1';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fanspeed} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fanspeed'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_nsSysHealthEntry}})) {
        next if ($oid !~ /^$mapping->{sysHealthCounterName}->{oid}\.(.*)$/);
        my $instance = $1;
        next if ($self->{results}->{$oid_nsSysHealthEntry}->{$oid} !~ /Speed|Fan/i);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_nsSysHealthEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fanspeed', instance => $instance));
        if ($result->{sysHealthCounterValue} == 0) {
            $self->{output}->output_add(long_msg => sprintf("skipping fan '%s' (counter is 0)", 
                                                            $result->{sysHealthCounterName}));
            next;
        }
        
        $self->{components}->{fanspeed}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan '%s' speed is %s C [instance = %s]",
                                                        $result->{sysHealthCounterName}, $result->{sysHealthCounterValue}, $instance));
        
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fanspeed', instance => $instance, value => $result->{sysHealthCounterValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' speed is %s rpm", $result->{sysHealthCounterName}, $result->{sysHealthCounterValue}));
        }
        $self->{output}->perfdata_add(
            label => 'speed', unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $result->{sysHealthCounterName},
            value => $result->{sysHealthCounterValue},
            warning => $warn,
            critical => $crit, min => 0
        );
    }
}

1;
