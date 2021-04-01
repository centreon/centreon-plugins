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

package hardware::server::dell::openmanage::snmp::mode::components::globalstatus;

use strict;
use warnings;

my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

# In MIB '10892.mib'
my $mapping = {
    globalSystemStatus => { oid => '.1.3.6.1.4.1.674.10892.1.200.10.1.2', map => \%map_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{globalSystemStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking global system status");
    $self->{components}->{globalstatus} = {name => 'global system status', total => 0, skip => 0};
    return if ($self->check_filter(section => 'globalstatus'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{globalSystemStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping->{globalSystemStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{globalSystemStatus}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'globalstatus', instance => $instance));
        
        $self->{components}->{globalstatus}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Chassis '%s' global status is '%s' [instance: %s]",
                                    $instance, $result->{globalSystemStatus}, $instance
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'globalstatus', value => $result->{globalSystemStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Chassis '%s' global status is '%s'",
                                           $instance, $result->{globalSystemStatus}));
        }
    }
}

1;
