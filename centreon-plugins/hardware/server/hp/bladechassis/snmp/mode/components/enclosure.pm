#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::server::hp::bladechassis::snmp::mode::components::enclosure;

use strict;
use warnings;

my %map_conditions = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

sub check {
    my ($self) = @_;

    my $oid_cpqRackCommonEnclosurePartNumber = '.1.3.6.1.4.1.232.22.2.3.1.1.1.5.1';
    my $oid_cpqRackCommonEnclosureSparePartNumber = '.1.3.6.1.4.1.232.22.2.3.1.1.1.6.1';
    my $oid_cpqRackCommonEnclosureSerialNum = '.1.3.6.1.4.1.232.22.2.3.1.1.1.7.1';
    my $oid_cpqRackCommonEnclosureFWRev = '.1.3.6.1.4.1.232.22.2.3.1.1.1.8.1';
    my $oid_cpqRackCommonEnclosureCondition = '.1.3.6.1.4.1.232.22.2.3.1.1.1.16.1';
    
    $self->{components}->{enclosure} = {name => 'enclosure', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking enclosure");
    return if ($self->check_exclude(section => 'enclosure'));
  
    my $result = $self->{snmp}->get_leef(oids => [$oid_cpqRackCommonEnclosurePartNumber, $oid_cpqRackCommonEnclosureSparePartNumber, 
                                                  $oid_cpqRackCommonEnclosureSerialNum, $oid_cpqRackCommonEnclosureFWRev,
                                                  $oid_cpqRackCommonEnclosureCondition], nothing_quit => 1);  
    $self->{components}->{enclosure}->{total}++;
    
    $self->{output}->output_add(long_msg => sprintf("Enclosure overall health condition is %s [part: %s, spare: %s, sn: %s, fw: %s].", 
                                $map_conditions{$result->{$oid_cpqRackCommonEnclosureCondition}},
                                $result->{$oid_cpqRackCommonEnclosurePartNumber},
                                $result->{$oid_cpqRackCommonEnclosureSparePartNumber},
                                $result->{$oid_cpqRackCommonEnclosureSerialNum},
                                $result->{$oid_cpqRackCommonEnclosureFWRev}));
    my $exit = $self->get_severity(section => 'enclosure', value => $map_conditions{$result->{$oid_cpqRackCommonEnclosureCondition}});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Enclosure overall health condition is %s", $map_conditions{$result->{$oid_cpqRackCommonEnclosureCondition}}));
    }
}

1;