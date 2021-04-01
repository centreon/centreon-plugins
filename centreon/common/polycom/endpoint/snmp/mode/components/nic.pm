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

package centreon::common::polycom::endpoint::snmp::mode::components::nic;

use strict;
use warnings;
use centreon::common::polycom::endpoint::snmp::mode::components::resources qw($map_status);

my $mapping = {
    hardwareNICNICsName   => { oid => '.1.3.6.1.4.1.13885.101.1.3.10.2.1.2' },
    hardwareNICNICsStatus => { oid => '.1.3.6.1.4.1.13885.101.1.3.10.2.1.6', map => $map_status },
};
my $oid_hardwareNICNICsEntry = '.1.3.6.1.4.1.13885.101.1.3.10.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hardwareNICNICsEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking nics");
    $self->{components}->{nic} = {name => 'nics', total => 0, skip => 0};
    return if ($self->check_filter(section => 'nic'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hardwareNICNICsEntry}})) {
        next if ($oid !~ /^$mapping->{hardwareNICNICsStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hardwareNICNICsEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'nic', instance => $instance));
        $self->{components}->{nic}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "nic '%s' status is '%s' [instance = %s]",
                $result->{hardwareNICNICsName},
                $result->{hardwareNICNICsStatus},
                $instance, 
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'nic', instance => $instance, value => $result->{hardwareNICNICsStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Nic '%s' status is '%s'",
                    $result->{hardwareNICNICsName},
                    $result->{hardwareNICNICsStatus}
                )
            );
        }
    }
}

1;
