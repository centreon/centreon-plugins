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

package network::netgear::mseries::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (
    1 => 'notpresent', 2 => 'operational', 3 => 'failed', 4 => 'powering', 
    5 => 'nopower', 6 => 'notpowering', 7 => 'incompatible'
);

my $mapping = {
    boxServicesFanItemState => { oid => '.1.3.6.1.4.1.4526.10.43.1.6.1.3', map => \%map_fan_status },
    boxServicesFanSpeed     => { oid => '.1.3.6.1.4.1.4526.10.43.1.6.1.4' },
};
my $oid_boxServicesFansEntry = '.1.3.6.1.4.1.4526.10.43.1.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_boxServicesFansEntry, begin => $mapping->{boxServicesFanItemState}->{oid}, end => $mapping->{boxServicesFanSpeed}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_boxServicesFansEntry}})) {
        next if ($oid !~ /^$mapping->{boxServicesFanItemState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_boxServicesFansEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        if ($result->{boxServicesFanItemState} =~ /notpresent/i) {
            $self->absent_problem(section => 'fan', instance => $instance);
            next;
        }

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s, speed = %s]",
                                                        $instance, $result->{boxServicesFanItemState}, $instance, defined($result->{boxServicesFanSpeed}) ? $result->{boxServicesFanSpeed} : 'unknown'));
        $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{boxServicesFanItemState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $instance, $result->{boxServicesFanItemState}));
        }
        
        next if (!defined($result->{boxServicesFanSpeed}) || $result->{boxServicesFanSpeed} !~ /[0-9]+/);
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{boxServicesFanSpeed});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' is '%s' rpm", $instance, $result->{boxServicesFanSpeed}));
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $instance,
            value => $result->{boxServicesFanSpeed},
            warning => $warn,
            critical => $crit, min => 0
        );
    }
}

1;
