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

package centreon::common::broadcom::megaraid::snmp::mode::components::vdrive;

use strict;
use warnings;

my %map_vdrive_status = (
    0 => 'offline', 1 => 'partially-degraded', 2 => 'degraded', 3 => 'optimal'
);

my $mapping = {
    state => { oid => '.1.3.6.1.4.1.3582.4.1.4.3.1.2.1.5', map => \%map_vdrive_status },
    name => { oid => '.1.3.6.1.4.1.3582.4.1.4.3.1.2.1.6' },
};
my $oid_virtualDriveEntry = '.1.3.6.1.4.1.3582.4.1.4.3.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_virtualDriveEntry, start => $mapping->{state}->{oid}, 
        end => $mapping->{name}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking virtual drives");
    $self->{components}->{vdrive} = {name => 'vdrives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'vdrive'));
    
    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_virtualDriveEntry}})) {
        next if ($oid !~ /^$mapping->{state}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_virtualDriveEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'vdrive', instance => $instance));
        if ($result->{state} =~ /status-not-installed/i) {
            $self->absent_problem(section => 'vdrive', instance => $instance);
            next;
        }

        $self->{components}->{vdrive}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Virtual drive '%s' status is '%s' [instance = %s, name = %s]",
                                                        $instance, $result->{state}, $instance, $result->{name}));
        $exit = $self->get_severity(label => 'vdrive', section => 'vdrive', value => $result->{state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Virtual drive '%s' status is '%s'", $instance, $result->{state}));
        }
    }
}

1;
