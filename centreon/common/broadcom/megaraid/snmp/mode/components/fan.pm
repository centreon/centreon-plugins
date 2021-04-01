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

package centreon::common::broadcom::megaraid::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (
    1 => 'status-invalid', 2 => 'status-ok', 3 => 'status-critical', 4 => 'status-nonCritical', 
    5 => 'status-unrecoverable', 6 => 'status-not-installed', 7 => 'status-unknown', 8 => 'status-not-available'
);

my $mapping = {
    enclosureId => { oid => '.1.3.6.1.4.1.3582.4.1.5.3.1.2' },
    fanStatus => { oid => '.1.3.6.1.4.1.3582.4.1.5.3.1.3', map => \%map_fan_status },
};
my $oid_enclosureFanEntry = '.1.3.6.1.4.1.3582.4.1.5.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclosureFanEntry, start => $mapping->{enclosureId}->{oid}, 
        end => $mapping->{fanStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fan', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_enclosureFanEntry}})) {
        next if ($oid !~ /^$mapping->{fanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclosureFanEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        if ($result->{fanStatus} =~ /status-not-installed/i) {
            $self->absent_problem(section => 'fan', instance => $instance);
            next;
        }

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is '%s' [instance = %s, enclosure = %s]",
                                                        $instance, $result->{fanStatus}, $instance, $result->{enclosureId}));
        $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{fanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $instance, $result->{fanStatus}));
        }
    }
}

1;
