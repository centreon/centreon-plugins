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

package network::audiocodes::snmp::mode::components::module;

use strict;
use warnings;

my %map_status = (
    1 => 'moduleNotExist',
    2 => 'moduleExistOk',
    3 => 'moduleOutOfService',
    4 => 'moduleBackToServiceStart',
    5 => 'moduleMismatch',
    6 => 'moduleFaulty',
    7 => 'notApplicable',
);
my %map_existence = (
    1 => 'present',
    2 => 'missing',
);

my $mapping = {
    acSysModulePresence     => { oid => '.1.3.6.1.4.1.5003.9.10.10.4.21.1.4', map => \%map_existence },
    acSysModuleFRUstatus    => { oid => '.1.3.6.1.4.1.5003.9.10.10.4.21.1.14', map => \%map_status },
};
my $oid_acSysModuleEntry = '.1.3.6.1.4.1.5003.9.10.10.4.21.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_acSysModuleEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking modules");
    $self->{components}->{module} = {name => 'modules', total => 0, skip => 0};
    return if ($self->check_filter(section => 'module'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_acSysModuleEntry}})) {
        next if ($oid !~ /^$mapping->{acSysModuleFRUstatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_acSysModuleEntry}, instance => $instance);
        
        next if ($result->{acSysModulePresence} eq 'missing' &&
                 $self->absent_problem(section => 'module', instance => $instance));
        next if ($self->check_filter(section => 'module', instance => $instance));

        $self->{components}->{module}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("module '%s' status is '%s' [instance = %s]",
                                                        $instance, $result->{acSysModuleFRUstatus}, $instance));
        my $exit = $self->get_severity(section => 'module', value => $result->{acSysModuleFRUstatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Module '%s' status is '%s'", $instance, $result->{acSysModuleFRUstatus}));
        }
    }
}

1;