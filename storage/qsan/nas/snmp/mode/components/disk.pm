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

package storage::qsan::nas::snmp::mode::components::disk;

use strict;
use warnings;

my $mapping = {
    pd_location         => { oid => '.1.3.6.1.4.1.22274.2.2.1.1.1' },
    pd_status_health    => { oid => '.1.3.6.1.4.1.22274.2.2.1.1.3' },
    hdd_temperature     => { oid => '.1.3.6.1.4.1.22274.2.3.4.1.4' },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{pd_location}->{oid} },
        { oid => $mapping->{pd_status_health}->{oid} }, { oid => $mapping->{hdd_temperature}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));

    my $results = { %{$self->{results}->{$mapping->{pd_location}->{oid}}}, %{$self->{results}->{$mapping->{pd_status_health}->{oid}}},
        %{$self->{results}->{$mapping->{hdd_temperature}->{oid}}}};
    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{pd_status_health}->{oid}}})) {
        $oid =~ /^$mapping->{pd_status_health}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        
        next if ($self->check_filter(section => 'disk', instance => $instance));

        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("disk '%s' status is '%s' [instance = %s, temperature = %s]",
                                                        $result->{pd_location}, $result->{pd_status_health}, $instance, $result->{hdd_temperature}));
        $exit = $self->get_severity(section => 'disk', value => $result->{pd_status_health});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is '%s'", $result->{pd_location}, $result->{pd_status_health}));
        }
        
        next if (!defined($result->{hdd_temperature}) || $result->{hdd_temperature} !~ /[0-9]/);
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'disk.temperature', instance => $instance, value => $result->{hdd_temperature});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' is '%s' C", $result->{pd_location}, $result->{hdd_temperature}));
        }
        $self->{output}->perfdata_add(
            label => 'disk_temperature', unit => 'C',
            nlabel => 'hardware.disk.temperature.celsius',
            instances => $result->{pd_location}, 
            value => $result->{hdd_temperature},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
