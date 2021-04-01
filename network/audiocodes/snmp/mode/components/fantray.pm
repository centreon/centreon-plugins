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

package network::audiocodes::snmp::mode::components::fantray;

use strict;
use warnings;

my %map_status = (
    0 => 'cleared',
    1 => 'indeterminate',
    2 => 'warning',
    3 => 'minor',
    4 => 'major',
    5 => 'critical',
);
my %map_existence = (
    1 => 'present',
    2 => 'missing',
);

my $mapping = {
    acSysFanTrayExistence   => { oid => '.1.3.6.1.4.1.5003.9.10.10.4.22.1.3', map => \%map_existence },
    acSysFanTraySeverity    => { oid => '.1.3.6.1.4.1.5003.9.10.10.4.22.1.6', map => \%map_status },
};
my $oid_acSysFanTrayEntry = '.1.3.6.1.4.1.5003.9.10.10.4.22.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_acSysFanTrayEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fantray");
    $self->{components}->{fantray} = {name => 'fantray', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fantray'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_acSysFanTrayEntry}})) {
        next if ($oid !~ /^$mapping->{acSysFanTraySeverity}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_acSysFanTrayEntry}, instance => $instance);
        
        next if ($result->{acSysFanTrayExistence} eq 'missing' &&
                 $self->absent_problem(section => 'fantray', instance => $instance));
        next if ($self->check_filter(section => 'fantray', instance => $instance));

        $self->{components}->{fantray}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan tray '%s' status is '%s' [instance = %s]",
                                                        $instance, $result->{acSysFanTraySeverity}, $instance));
        my $exit = $self->get_severity(label => 'default', section => 'fantray', value => $result->{acSysFanTraySeverity});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan tray '%s' status is '%s'", $instance, $result->{acSysFanTraySeverity}));
        }
    }
}

1;