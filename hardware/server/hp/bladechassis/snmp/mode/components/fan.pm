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

package hardware::server::hp::bladechassis::snmp::mode::components::fan;

use strict;
use warnings;

my %map_conditions = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
    4 => 'Weird!!!', # for blades it can return 4, which is NOT spesified in MIB
);

my $mapping = {
    fan_part        => { oid => '.1.3.6.1.4.1.232.22.2.3.1.3.1.6' }, # cpqRackCommonEnclosureFanPartNumber
    fan_spare       => { oid => '.1.3.6.1.4.1.232.22.2.3.1.3.1.7' }, # cpqRackCommonEnclosureFanSparePartNumber
    fan_condition   => { oid => '.1.3.6.1.4.1.232.22.2.3.1.3.1.11', map => \%map_conditions  }, # cpqRackCommonEnclosureFanCondition
};

sub check {
    my ($self) = @_;

    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "checking fans");
    return if ($self->check_filter(section => 'fan'));
    
    my $oid_cpqRackCommonEnclosureFanPresent = '.1.3.6.1.4.1.232.22.2.3.1.3.1.8';
    
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureFanPresent);
    return if (scalar(keys %$snmp_result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        $key =~ /\.([0-9]+)$/;
        my $oid_end = $1;
        
        next if ($present_map{$snmp_result->{$key}} ne 'present' && 
                 $self->absent_problem(section => 'fan', instance => $oid_end));
        
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }

    $snmp_result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $fan_index = $_;

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $fan_index);
        next if ($self->check_filter(section => 'fan', instance => $fan_index));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan '%s' condition is %s [part: %s, spare: %s].", 
                                    $fan_index, $result->{fan_condition},
                                    $result->{fan_part}, $result->{fan_spare}));
        my $exit = $self->get_severity(label => 'default', section => 'fan', instance => $fan_index, value => $result->{fan_condition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' condition is %s", $fan_index, $result->{fan_condition}));
        }
    }
}

1;
