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

package network::hp::vc::snmp::mode::components::moduleport;

use strict;
use warnings;
use network::hp::vc::snmp::mode::components::resources qw($map_moduleport_loop_status $map_moduleport_protection_status);

my $mapping = {
    vcModulePortBpduLoopStatus => { oid => '.1.3.6.1.4.1.11.5.7.5.2.3.1.1.6.1.3', map => $map_moduleport_loop_status },
    vcModulePortProtectionStatus => { oid => '.1.3.6.1.4.1.11.5.7.5.2.3.1.1.6.1.4', map => $map_moduleport_protection_status },
};
my $oid_vcModulePortEntry = '.1.3.6.1.4.1.11.5.7.5.2.3.1.1.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_vcModulePortEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking module ports");
    $self->{components}->{moduleport} = { name => 'module ports', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'moduleport'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vcModulePortEntry}})) {
        next if ($oid !~ /^$mapping->{vcModulePortBpduLoopStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_vcModulePortEntry}, instance => $instance);

        next if ($self->check_filter(section => 'moduleport', instance => $instance));
        $self->{components}->{moduleport}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("module port '%s' loop status is '%s' [instance: %s, protection status: %s].",
                                    $instance, $result->{vcModulePortBpduLoopStatus},
                                    $instance, $result->{vcModulePortProtectionStatus}
                                    ));
        my $exit = $self->get_severity(section => 'moduleport.loop', value => $result->{vcModulePortBpduLoopStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Module port '%s' loop status is '%s'",
                                                             $instance, $result->{vcModulePortBpduLoopStatus}));
        }
        
        $exit = $self->get_severity(section => 'moduleport.protection', value => $result->{vcModulePortProtectionStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Module port '%s' protection status is '%s'",
                                                             $instance, $result->{vcModulePortProtectionStatus}));
        }
    }
}

1;