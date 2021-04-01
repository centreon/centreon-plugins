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

package centreon::common::cisco::standard::snmp::mode::components::physical;

use strict;
use warnings;

my %map_physical_state = (
    1 => 'other',
    2 => 'supported',
    3 => 'unsupported',
    4 => 'incompatible',
);

# In MIB 'CISCO-ENTITY-SENSOR-MIB'
my $mapping = {
    cefcPhysicalStatus => { oid => '.1.3.6.1.4.1.9.9.117.1.5.1.1.1', map => \%map_physical_state },
};
my $oid_cefcPhysicalStatus = '.1.3.6.1.4.1.9.9.117.1.5.1.1.1';
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cefcPhysicalStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking physicals");
    $self->{components}->{physical} = {name => 'physical', total => 0, skip => 0};
    return if ($self->check_filter(section => 'physical'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcPhysicalStatus}})) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cefcPhysicalStatus}, instance => $instance);
        my $physical_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        
        if (!defined($physical_descr)) {
            $self->{output}->output_add(long_msg => sprintf("skipped instance '%s': no description", $instance));
            next;
        }
        
        next if ($self->check_filter(section => 'physical', instance => $instance, name => $physical_descr));
        
        $self->{components}->{physical}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Physical '%s' status is %s [instance: %s]",
                                    $physical_descr, $result->{cefcPhysicalStatus}, $instance));
        my $exit = $self->get_severity(section => 'physical', instance => $instance, value => $result->{cefcPhysicalStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Physical '%s/%s' status is %s", $physical_descr, 
                                                                $instance, $result->{cefcPhysicalStatus}));
        }
    }
}

1;
