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

package centreon::common::cisco::standard::snmp::mode::components::module;

use strict;
use warnings;

my %map_module_state = (
    1 => 'unknown',
    2 => 'ok',
    3 => 'disabled',
    4 => 'okButDiagFailed',
    5 => 'boot',
    6 => 'selfTest',
    7 => 'failed',
    8 => 'missing',
    9 => 'mismatchWithParent',
    10 => 'mismatchConfig',
    11 => 'diagFailed',
    12 => 'dormant',
    13 => 'outOfServiceAdmin',
    14 => 'outOfServiceEnvTemp',
    15 => 'poweredDown',
    16 => 'poweredUp',
    17 => 'powerDenied',
    18 => 'powerCycled',
    19 => 'okButPowerOverWarning',
    20 => 'okButPowerOverCritical',
    21 => 'syncInProgress',
    22 => 'upgrading',
    23 => 'okButAuthFailed',
    24 => 'mdr',
    25 => 'fwMismatchFound',
    26 => 'fwDownloadSuccess',
    27 => 'fwDownloadFailure',
);

# In MIB 'CISCO-ENTITY-FRU-CONTROL-MIB'
my $mapping = {
    cefcModuleOperStatus => { oid => '.1.3.6.1.4.1.9.9.117.1.2.1.1.2', map => \%map_module_state },
};
my $oid_cefcModuleOperStatus = '.1.3.6.1.4.1.9.9.117.1.2.1.1.2';
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cefcModuleOperStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking modules");
    $self->{components}->{module} = {name => 'modules', total => 0, skip => 0};
    return if ($self->check_filter(section => 'module'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcModuleOperStatus}})) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cefcModuleOperStatus}, instance => $instance);
        my $module_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        
        next if ($self->check_filter(section => 'module', instance => $instance, name => $module_descr));
        
        $self->{components}->{module}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Module '%s' status is %s [instance: %s]",
                                    $module_descr, $result->{cefcModuleOperStatus}, $instance));
        my $exit = $self->get_severity(section => 'module', instance => $instance, value => $result->{cefcModuleOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Module '%s/%s' status is %s", $module_descr, 
                                                        $instance, $result->{cefcModuleOperStatus}));
        }
    }
}

1;
