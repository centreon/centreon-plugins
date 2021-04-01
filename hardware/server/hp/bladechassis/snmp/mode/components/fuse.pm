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

package hardware::server::hp::bladechassis::snmp::mode::components::fuse;

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
    fuse_name       => { oid => '.1.3.6.1.4.1.232.22.2.3.1.4.1.4' }, # cpqRackCommonEnclosureFuseEnclosureName
    fuse_location   => { oid => '.1.3.6.1.4.1.232.22.2.3.1.4.1.5' }, # cpqRackCommonEnclosureFuseLocation
    fuse_condition  => { oid => '.1.3.6.1.4.1.232.22.2.3.1.4.1.7', map => \%map_conditions  }, # cpqRackCommonEnclosureFuseCondition
};

sub check {
    my ($self) = @_;

    $self->{components}->{fuse} = {name => 'fuses', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "checking fuse");
    return if ($self->check_filter(section => 'fuse'));
    
    my $oid_cpqRackCommonEnclosureFusePresent = '.1.3.6.1.4.1.232.22.2.3.1.4.1.6';
    
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureFusePresent);
    return if (scalar(keys %$snmp_result) <= 0);

    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        $key =~ /^$oid_cpqRackCommonEnclosureFusePresent\.(.*)$/;
        my $oid_end = $1;
        
        next if ($present_map{$snmp_result->{$key}} ne 'present' && 
                 $self->absent_problem(section => 'fuse', instance => $oid_end));
        
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }
    
    $snmp_result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $fuse_index = $_;
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $fuse_index);
        next if ($self->check_filter(section => 'fuse', instance => $fuse_index));
        
        $self->{components}->{fuse}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fuse '%s' status is %s [name: %s, location: %s].",
                                    $fuse_index, $result->{fuse_condition},
                                    $result->{fuse_name}, $result->{fuse_location}));
        my $exit = $self->get_severity(label => 'default', section => 'fuse', instance => $fuse_index, value => $result->{fuse_condition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fuse '%s' status is %s",
                                            $fuse_index, $result->{fuse_condition}));
        }
    }
}

1;
