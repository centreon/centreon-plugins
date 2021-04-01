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

package centreon::common::broadcom::megaraid::snmp::mode::components::pdrive;

use strict;
use warnings;

my %map_pdrive_status = (
    0 => 'unconfigured-good', 1 => 'unconfigured-bad', 2 => 'hot-spare', 16 => 'offline',
    17 => 'failed', 20 => 'rebuild', 24 => 'online', 32 => 'copyback', 64 => 'system', 128 => 'UNCONFIGURED-SHIELDED',
    130 => 'HOTSPARE-SHIELDED', 144 => 'CONFIGURED-SHIELDED'
);

my $mapping = {
    pdState => { oid => '.1.3.6.1.4.1.3582.4.1.4.2.1.2.1.10', map => \%map_pdrive_status },
    pdSerialNumber => { oid => '.1.3.6.1.4.1.3582.4.1.4.2.1.2.1.37' },
};
my $oid_virtualDriveEntry = '.1.3.6.1.4.1.3582.4.1.4.2.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_virtualDriveEntry, start => $mapping->{pdState}->{oid}, 
        end => $mapping->{pdSerialNumber}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking physical drives");
    $self->{components}->{pdrive} = {name => 'pdrives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'pdrive'));
    
    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_virtualDriveEntry}})) {
        next if ($oid !~ /^$mapping->{pdState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_virtualDriveEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'pdrive', instance => $instance));
        if ($result->{pdState} =~ /status-not-installed/i) {
            $self->absent_problem(section => 'pdrive', instance => $instance);
            next;
        }

        $self->{components}->{pdrive}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Physical drive '%s' status is '%s' [instance = %s, SN = %s]",
                                                        $instance, $result->{pdState}, $instance, $result->{pdSerialNumber}));
        $exit = $self->get_severity(label => 'pdrive', section => 'pdrive', value => $result->{pdState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Physical drive '%s' status is '%s'", $instance, $result->{pdState}));
        }
    }
}

1;
