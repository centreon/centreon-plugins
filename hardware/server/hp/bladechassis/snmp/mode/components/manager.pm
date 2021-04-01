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

my %map_role = (
    1 => 'Standby',
    2 => 'Active',
);

my $mapping = {
    man_part        => { oid => '.1.3.6.1.4.1.232.22.2.3.1.6.1.6' }, # cpqRackCommonEnclosureManagerPartNumber
    man_spare       => { oid => '.1.3.6.1.4.1.232.22.2.3.1.6.1.7' }, # cpqRackCommonEnclosureManagerSparePartNumber
    man_serial      => { oid => '.1.3.6.1.4.1.232.22.2.3.1.6.1.8' }, # cpqRackCommonEnclosureManagerSerialNum
    man_role        => { oid => '.1.3.6.1.4.1.232.22.2.3.1.6.1.9', map => \%map_role }, # cpqRackCommonEnclosureManagerRole
    man_condition   => { oid => '.1.3.6.1.4.1.232.22.2.3.1.6.1.12', map => \%map_conditions }, # cpqRackCommonEnclosureManagerConditio
};

sub check {
    my ($self, %options) = @_;
    
    $self->{components}->{manager} = { name => 'managers', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'manager'));
    $self->{output}->output_add(long_msg => "checking managers");

    my $oid_cpqRackCommonEnclosureManagerIndex = '.1.3.6.1.4.1.232.22.2.3.1.6.1.3';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureManagerIndex);
    return if (scalar(keys %$snmp_result) <= 0);
    
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        $key =~ /^$oid_cpqRackCommonEnclosureManagerIndex\.(.*)$/;
        my $oid_end = $1;
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }

    $snmp_result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $instance = $_;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        next if ($self->check_filter(section => 'manager', instance => $instance));

        $self->{components}->{manager}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("enclosure management module '%s' is %s, status is %s [serial: %s, part: %s, spare: %s].", 
                                    $instance, $result->{man_condition}, $result->{man_role},
                                    $result->{man_serial}, $result->{man_part}, $result->{man_spare}));
        my $exit = $self->get_severity(label => 'default', section => 'manager', instance => $instance, value => $result->{man_condition});
        if ($result->{man_role} eq 'Active' && !$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Enclosure management module '%s' is %s, status is %s", 
                                            $instance, $result->{man_condition}, $result->{man_role}));
        }
    }
}

1;
