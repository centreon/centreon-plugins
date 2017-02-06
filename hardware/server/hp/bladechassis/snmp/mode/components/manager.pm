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

package hardware::server::hp::bladechassis::snmp::mode::components::manager;

use strict;
use warnings;

my %map_conditions = (
    0 => 'other', # maybe on standby mode only!!
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %conditions = (
    0 => ['other', 'UNKNOWN'], # maybe on standby mode only!!
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL'],
);

my %map_role = (
    1 => 'Standby',
    2 => 'Active',
);

sub check {
    my ($self, %options) = @_;
    
    $self->{components}->{manager} = {name => 'managers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'manager'));

    # No check if OK
    if ((!defined($options{force}) || $options{force} != 1) && $self->{output}->is_status(compare => 'ok', litteral => 1)) {
        return ;
    }
    $self->{output}->output_add(long_msg => "Checking managers");
    
    my $oid_cpqRackCommonEnclosureManagerIndex = '.1.3.6.1.4.1.232.22.2.3.1.6.1.3';
    my $oid_cpqRackCommonEnclosureManagerPartNumber = '.1.3.6.1.4.1.232.22.2.3.1.6.1.6';
    my $oid_cpqRackCommonEnclosureManagerSparePartNumber = '.1.3.6.1.4.1.232.22.2.3.1.6.1.7';
    my $oid_cpqRackCommonEnclosureManagerSerialNum = '.1.3.6.1.4.1.232.22.2.3.1.6.1.8';
    my $oid_cpqRackCommonEnclosureManagerRole = '.1.3.6.1.4.1.232.22.2.3.1.6.1.9';
    my $oid_cpqRackCommonEnclosureManagerCondition = '.1.3.6.1.4.1.232.22.2.3.1.6.1.12';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureManagerIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqRackCommonEnclosureManagerPartNumber, $oid_cpqRackCommonEnclosureManagerSparePartNumber,
                                $oid_cpqRackCommonEnclosureManagerSerialNum, $oid_cpqRackCommonEnclosureManagerRole,
                                $oid_cpqRackCommonEnclosureManagerCondition],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;
    
        my $man_part = $result2->{$oid_cpqRackCommonEnclosureManagerPartNumber . '.' . $instance};
        my $man_spare = $result2->{$oid_cpqRackCommonEnclosureManagerSparePartNumber . '.' . $instance};
        my $man_serial = $result2->{$oid_cpqRackCommonEnclosureManagerSerialNum . '.' . $instance};
        my $man_role = $result2->{$oid_cpqRackCommonEnclosureManagerRole . '.' . $instance};
        my $man_condition = $result2->{$oid_cpqRackCommonEnclosureManagerCondition . '.' . $instance};
        
        next if ($self->check_exclude(section => 'manager', instance => $instance));

        $self->{components}->{manager}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Enclosure management module %d is %s, status is %s [serial: %s, part: %s, spare: %s].", 
                                    $instance, $map_conditions{$man_condition}, $map_role{$man_role},
                                    $man_serial, $man_part, $man_spare));
        my $exit = $self->get_severity(section => 'manager', value => $map_conditions{$man_condition});
        if ($man_role == 2 && !$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Enclosure management module %d is %s, status is %s", 
                                            $instance, $map_conditions{$man_condition}, $map_role{$man_role}));
        }
    }
}

1;