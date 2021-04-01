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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::global;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_global_status = (
    0 => 'non recoverable',
    2 => 'critical',
    4 => 'non critical',
    255 => 'nominal',
);

my $mapping = {
    systemHealthStat => { oid => '.1.3.6.1.4.1.2.3.51.3.1.4.1', map => \%map_global_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{systemHealthStat}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking system health");
    $self->{components}->{global} = {name => 'system health', total => 0, skip => 0};
    return if ($self->check_filter(section => 'global'));
    
    return if (!defined($self->{results}->{$mapping->{systemHealthStat}->{oid}}) || scalar(keys %{$self->{results}->{$mapping->{systemHealthStat}->{oid}}}) <= 0);
    
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{systemHealthStat}->{oid}}, instance => '0');
    $self->{components}->{global}->{total}++;
    
    $self->{output}->output_add(
        long_msg => sprintf(
            "system health status is '%s'", 
            $result->{systemHealthStat}
        )
    );
    my $exit = $self->get_severity(section => 'global', value => $result->{systemHealthStat});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "System health status is '%s'.", 
                $result->{systemHealthStat}
            )
        );
    }
}

1;
