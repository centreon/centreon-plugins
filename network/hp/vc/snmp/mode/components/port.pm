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

package network::hp::vc::snmp::mode::components::port;

use strict;
use warnings;
use network::hp::vc::snmp::mode::components::resources qw($map_managed_status $map_reason_code);

my $mapping = {
    vcPortManagedStatus => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.4.1.1.3', map => $map_managed_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{vcPortManagedStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ports");
    $self->{components}->{port} = { name => 'ports', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'port'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{vcPortManagedStatus}->{oid}}})) {
        $oid =~ /^$mapping->{vcPortManagedStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{vcPortManagedStatus}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'port', instance => $instance));
        $self->{components}->{port}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("port '%s' status is '%s' [instance: %s].",
                                    $instance, $result->{vcPortManagedStatus},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'port', label => 'default', value => $result->{vcPortManagedStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Port '%s' status is '%s'",
                                                             $instance, $result->{vcPortManagedStatus}));
        }
    }
}

1;