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

package hardware::server::hp::bladechassis::snmp::mode::components::blade;

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
    blade_name      => { oid => '.1.3.6.1.4.1.232.22.2.4.1.1.1.4' }, # cpqRackServerBladeName
    blade_part      => { oid => '.1.3.6.1.4.1.232.22.2.4.1.1.1.6' }, # cpqRackServerBladePartNumber
    blade_status    => { oid => '.1.3.6.1.4.1.232.22.2.3.1.3.1.11', map => \%map_conditions  }, # cpqRackServerBladeStatus (v2)
    blade_spare     => { oid => '.1.3.6.1.4.1.232.22.2.4.1.1.1.21' }, # cpqRackServerBladeSparePartNumber
    blade_productid => { oid => '.1.3.6.1.4.1.232.22.2.4.1.1.1.17' }, # cpqRackServerBladeProductId
    blade_diago     => { oid => '.1.3.6.1.4.1.232.22.2.4.1.1.1.24' }, # cpqRackServerBladeFaultDiagnosticString (v2)
};

sub check {
    my ($self) = @_;

    $self->{components}->{blade} = {name => 'blades', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "checking blades");
    return if ($self->check_filter(section => 'blade'));
    
    my $oid_cpqRackServerBladePresent = '.1.3.6.1.4.1.232.22.2.4.1.1.1.12';
    
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackServerBladePresent);
    return if (scalar(keys %$snmp_result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {       
        $key =~ /\.([0-9]+)$/;
        my $oid_end = $1;
        
        next if ($present_map{$snmp_result->{$key}} ne 'present' && 
                 $self->absent_problem(section => 'blade', instance => $oid_end));
        
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }

    $snmp_result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $blade_index = $_;

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $blade_index);
        next if ($self->check_filter(section => 'blade', instance => $blade_index));
        
        $self->{components}->{blade}->{total}++;
        if (!defined($result->{blade_status})) {
            $self->{output}->output_add(long_msg => sprintf("skipping blade '%s' (%s, %s). Cant get status.",
                                        $blade_index, $result->{blade_name}, $result->{blade_productid}));
            next;
        }
        
        $self->{output}->output_add(
            long_msg => sprintf("blade '%s' (%s, %s) status is %s [part: %s, spare: %s]%s.",
                $blade_index, $result->{blade_name}, $result->{blade_productid},
                $result->{blade_status},
                $result->{blade_part}, $result->{blade_spare},
                defined($result->{blade_diago}) ? " (Diagnostic '$result->{blade_diago}')" : ''
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'blade', instance => $blade_index, value => $result->{blade_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Blade '%s' (%s, %s) status is %s",
                    $blade_index, $result->{blade_name}, $result->{blade_productid},
                    $result->{blade_status}
                )
            );
        }
    }
}

1;
