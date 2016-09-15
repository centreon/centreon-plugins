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

package hardware::server::dell::idrac::snmp::mode::components::storagebattery;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status);

my $mapping = {
    batteryComponentStatus  => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.15.1.6', map => \%map_status },
    batteryFQDD             => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.15.1.20' },
};
my $oid_batteryTableEntry = '.1.3.6.1.4.1.674.10892.5.5.1.20.130.15.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_batteryTableEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking storage batteries");
    $self->{components}->{storagebattery} = {name => 'storage batteries', total => 0, skip => 0};
    return if ($self->check_filter(section => 'storagebattery'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_batteryTableEntry}})) {
        next if ($oid !~ /^$mapping->{batteryComponentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_batteryTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'storagebattery', instance => $instance));
        $self->{components}->{storagebattery}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("storage battery '%s' status is '%s' [instance = %s]",
                                    $result->{batteryFQDD}, $result->{batteryComponentStatus}, $instance, 
                                    ));

        my $exit = $self->get_severity(label => 'default.status', section => 'storagebattery.status', value => $result->{batteryComponentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Storage battery '%s' status is '%s'", $result->{batteryFQDD}, $result->{batteryComponentStatus}));
        }
    }
}

1;