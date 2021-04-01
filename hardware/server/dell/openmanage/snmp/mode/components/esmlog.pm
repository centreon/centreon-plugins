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

package hardware::server::dell::openmanage::snmp::mode::components::esmlog;

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
    systemStateEventLogStatus => { oid => '.1.3.6.1.4.1.674.10892.1.200.10.1.41', map => \%map_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{systemStateEventLogStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking ESM log filling");
    $self->{components}->{esmlog} = {name => 'ESM log', total => 0, skip => 0};
    return if ($self->check_filter(section => 'esmlog'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{systemStateEventLogStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping->{systemStateEventLogStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{systemStateEventLogStatus}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'globalstatus', instance => $instance));
        
        $self->{components}->{esmlog}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("ESM '%s' log status is '%s' [instance: %s]",
                                    $instance, $result->{systemStateEventLogStatus}, $instance
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'esmlog', value => $result->{systemStateEventLogStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("ESM '%s' log status is '%s'",
                                           $instance, $result->{systemStateEventLogStatus}));
        }
    }
}

1;
