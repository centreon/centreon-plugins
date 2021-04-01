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

package centreon::common::ibm::tapelibrary::snmp::mode::components::psu;

use strict;
use warnings;
use centreon::common::ibm::tapelibrary::snmp::mode::components::resources qw($map_status);

my $mapping = {
    chassis_PS1Status       => { oid => '.1.3.6.1.4.1.2.6.257.1.3.2.1.3', map => $map_status },
    chassis_PS2Status       => { oid => '.1.3.6.1.4.1.2.6.257.1.3.2.1.4', map => $map_status },
    chassis_SerialNumber    => { oid => '.1.3.6.1.4.1.2.6.257.1.3.2.1.9' },
};
my $oid_frameConfigEntry = '.1.3.6.1.4.1.2.6.257.1.3.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_frameConfigEntry };
}

sub check_psu {
    my ($self, %options) = @_;
     
    return if ($self->check_filter(section => 'psu', instance => $options{instance}));
    $self->{components}->{psu}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("psu '%s' status is '%s' [instance: %s, chassis: %s].",
                                    $options{instance}, $options{status},
                                    $options{instance}, $options{serial}
                                    ));
    my $exit = $self->get_severity(label => 'status', section => 'psu', value => $options{status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity =>  $exit,
                                    short_msg => sprintf("psu '%s' status is '%s'",
                                                         $options{instance}, $options{status}));
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_frameConfigEntry}})) {
        next if ($oid !~ /^$mapping->{chassis_SerialNumber}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_frameConfigEntry}, instance => $instance);

        check_psu($self, status => $result->{chassis_PS1Status}, instance => $instance . '.1', serial => $result->{chassis_SerialNumber});
        check_psu($self, status => $result->{chassis_PS2Status}, instance => $instance . '.2', serial => $result->{chassis_SerialNumber});        
    }
}

1;