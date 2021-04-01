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

package network::dell::os10::snmp::mode::components::fantray;

use strict;
use warnings;
use network::dell::os10::snmp::mode::components::resources qw($map_oper_status);

my $mapping = {
    os10FanTrayOperStatus => { oid => '.1.3.6.1.4.1.674.11000.5000.100.4.1.2.2.1.4', map => $map_oper_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{os10FanTrayOperStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking fantray");
    $self->{components}->{fantray} = { name => 'fantray', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fantray'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{os10FanTrayOperStatus}->{oid} }})) {
        $oid =~ /^$mapping->{os10FanTrayOperStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{os10FanTrayOperStatus}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'fantray', instance => $instance));
        $self->{components}->{fantray}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fantray '%s' status is '%s' [instance: %s].",
                $instance,
                $result->{os10FanTrayOperStatus},
                $instance
            )
        );
        my $exit = $self->get_severity(label => 'operational', section => 'fantray', value => $result->{os10FanTrayOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fantray '%s' status is '%s'",
                    $instance,
                    $result->{os10FanTrayOperStatus}
                )
            );
        }
    }
}

1;
