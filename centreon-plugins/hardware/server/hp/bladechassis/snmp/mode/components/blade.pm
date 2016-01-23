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

sub check {
    my ($self) = @_;

    $self->{components}->{blade} = {name => 'blades', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking blades");
    return if ($self->check_exclude(section => 'blade'));
    
    my $oid_cpqRackServerBladePresent = '.1.3.6.1.4.1.232.22.2.4.1.1.1.12';
    my $oid_cpqRackServerBladeIndex = '.1.3.6.1.4.1.232.22.2.4.1.1.1.3';
    my $oid_cpqRackServerBladeName = '.1.3.6.1.4.1.232.22.2.4.1.1.1.4';
    my $oid_cpqRackServerBladePartNumber = '.1.3.6.1.4.1.232.22.2.4.1.1.1.6';
    my $oid_cpqRackServerBladeSparePartNumber = '.1.3.6.1.4.1.232.22.2.4.1.1.1.7';
    my $oid_cpqRackServerBladeProductId = '.1.3.6.1.4.1.232.22.2.4.1.1.1.17';
    my $oid_cpqRackServerBladeStatus = '.1.3.6.1.4.1.232.22.2.4.1.1.1.21'; # v2
    my $oid_cpqRackServerBladeFaultDiagnosticString = '.1.3.6.1.4.1.232.22.2.4.1.1.1.24'; # v2
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackServerBladePresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {       
        $key =~ /\.([0-9]+)$/;
        my $oid_end = $1;
        
        next if ($present_map{$result->{$key}} ne 'present' && 
                 $self->absent_problem(section => 'blade', instance => $oid_end));
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cpqRackServerBladeIndex . "." . $oid_end, $oid_cpqRackServerBladeName . "." . $oid_end,
                $oid_cpqRackServerBladePartNumber . "." . $oid_end, $oid_cpqRackServerBladeSparePartNumber . "." . $oid_end,
                $oid_cpqRackServerBladeProductId . "." . $oid_end, 
                $oid_cpqRackServerBladeStatus . "." . $oid_end, $oid_cpqRackServerBladeFaultDiagnosticString . "." . $oid_end;
    }

    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $blade_index = $result->{$oid_cpqRackServerBladeIndex . '.' . $_};
        my $blade_status = defined($result->{$oid_cpqRackServerBladeStatus . '.' . $_}) ? $result->{$oid_cpqRackServerBladeStatus . '.' . $_} : '';
        my $blade_name = $result->{$oid_cpqRackServerBladeName . '.' . $_};
        my $blade_part = $result->{$oid_cpqRackServerBladePartNumber . '.' . $_};
        my $blade_spare = $result->{$oid_cpqRackServerBladeSparePartNumber . '.' . $_};
        my $blade_productid = $result->{$oid_cpqRackServerBladeProductId . '.' . $_};
        my $blade_diago = defined($result->{$oid_cpqRackServerBladeFaultDiagnosticString . '.' . $_}) ? $result->{$oid_cpqRackServerBladeFaultDiagnosticString . '.' . $_} : '';
        
        next if ($self->check_exclude(section => 'blade', instance => $blade_index));
        
        $self->{components}->{blade}->{total}++;
        if ($blade_status eq '') {
            $self->{output}->output_add(long_msg => sprintf("Skipping Blade %d (%s, %s). Cant get status.",
                                        $blade_index, $blade_name, $blade_productid));
            next;
        }
        
        $self->{output}->output_add(long_msg => sprintf("Blade %d (%s, %s) status is %s [part: %s, spare: %s]%s.",
                                    $blade_index, $blade_name, $blade_productid,
                                    $map_conditions{$blade_status},
                                    $blade_part, $blade_spare,
                                    ($blade_diago ne '') ? " (Diagnostic '$blade_diago')" : ''
                                    ));
        my $exit = $self->get_severity(section => 'blade', value => $map_conditions{$blade_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Blade %d (%s, %s) status is %s",
                                            $blade_index, $blade_name, $blade_productid,
                                            $map_conditions{$blade_status}
                                       ));
        }
    }
}

1;