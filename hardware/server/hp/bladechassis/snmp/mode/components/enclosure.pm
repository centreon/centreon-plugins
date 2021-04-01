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

package hardware::server::hp::bladechassis::snmp::mode::components::enclosure;

use strict;
use warnings;

my $map_conditions = {
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
};

my $mapping = {
    cpqRackCommonEnclosureSparePartNumber   => { oid => '.1.3.6.1.4.1.232.22.2.3.1.1.1.6' },
    cpqRackCommonEnclosureSerialNum         => { oid => '.1.3.6.1.4.1.232.22.2.3.1.1.1.7' },
    cpqRackCommonEnclosureFWRev             => { oid => '.1.3.6.1.4.1.232.22.2.3.1.1.1.8' },
    cpqRackCommonEnclosureCondition         => { oid => '.1.3.6.1.4.1.232.22.2.3.1.1.1.16', map => $map_conditions },
};

sub check {
    my ($self) = @_;
    
    $self->{components}->{enclosure} = {name => 'enclosure', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "checking enclosure");
    return if ($self->check_filter(section => 'enclosure'));

    my $oid_cpqRackCommonEnclosurePartNumber = '.1.3.6.1.4.1.232.22.2.3.1.1.1.5';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosurePartNumber);
    return if (scalar(keys %$snmp_result) <= 0);

    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        $key =~ /^$oid_cpqRackCommonEnclosurePartNumber\.(.*)$/;
        my $oid_end = $1;
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }

	my $snmp_result2 = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $instance = $_;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result2, instance => $instance);
        
        next if ($self->check_filter(section => 'enclosure', instance => $instance));
		
        $self->{components}->{enclosure}->{total}++;
        
        $self->{output}->output_add(long_msg => 
            sprintf("enclosure '%s' overall health condition is %s [part: %s, spare: %s, sn: %s, fw: %s].",
                $instance,
                $result->{cpqRackCommonEnclosureCondition},
                $snmp_result->{$oid_cpqRackCommonEnclosurePartNumber . '.' . $instance},
                $result->{cpqRackCommonEnclosureSparePartNumber},
                $result->{cpqRackCommonEnclosureSerialNum},
                $result->{cpqRackCommonEnclosureFWRev}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'enclosure', value => $result->{cpqRackCommonEnclosureCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Enclosure '%s' overall health condition is %s", $instance, $result->{cpqRackCommonEnclosureCondition}));
        }
    }
}

1;
