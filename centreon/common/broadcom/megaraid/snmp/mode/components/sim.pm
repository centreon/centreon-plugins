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

package centreon::common::broadcom::megaraid::snmp::mode::components::sim;

use strict;
use warnings;

my %map_slot_status = (
    1 => 'status-invalid', 2 => 'status-ok', 3 => 'status-critical', 4 => 'status-nonCritical', 
    5 => 'status-unrecoverable', 6 => 'status-not-installed', 7 => 'status-unknown', 8 => 'status-not-available'
);

my $mapping = {
    enclosureId_ESIT => { oid => '.1.3.6.1.4.1.3582.4.1.5.8.1.2' },
    slotStatus => { oid => '.1.3.6.1.4.1.3582.4.1.5.8.1.3', map => \%map_slot_status },
};
my $oid_enclosureSIMEntry = '.1.3.6.1.4.1.3582.4.1.5.8.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclosureSIMEntry, start => $mapping->{enclosureId_ESIT}->{oid}, 
        end => $mapping->{slotStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking SIMs");
    $self->{components}->{sim} = {name => 'sims', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sim'));
    
    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_enclosureSIMEntry}})) {
        next if ($oid !~ /^$mapping->{slotStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclosureSIMEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'sim', instance => $instance));
        if ($result->{slotStatus} =~ /status-not-installed/i) {
            $self->absent_problem(section => 'sim', instance => $instance);
            next;
        }

        $self->{components}->{sim}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Sim '%s' status is '%s' [instance = %s, enclosure = %s]",
                                                        $instance, $result->{slotStatus}, $instance, $result->{enclosureId_ESIT}));
        $exit = $self->get_severity(label => 'default', section => 'sim', value => $result->{slotStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sim '%s' status is '%s'", $instance, $result->{slotStatus}));
        }
    }
}

1;
