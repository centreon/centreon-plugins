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

package hardware::server::dell::idrac::snmp::mode::components::fru;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status);

my $mapping = {
    fruInformationStatus    => { oid => '.1.3.6.1.4.1.674.10892.5.4.2000.10.1.3', map => \%map_status },
    fruSerialNumberName     => { oid => '.1.3.6.1.4.1.674.10892.5.4.2000.10.1.7' }
};
my $oid_fruTableEntry = '.1.3.6.1.4.1.674.10892.5.4.2000.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_fruTableEntry,
        start => $mapping->{fruInformationStatus}->{oid},
        end => $mapping->{fruSerialNumberName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fru");
    $self->{components}->{fru} = {name => 'fru', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fru'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fruTableEntry}})) {
        next if ($oid !~ /^$mapping->{fruInformationStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fruTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fru', instance => $instance));
        $self->{components}->{fru}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fru '%s' status is '%s' [instance = %s]",
                $result->{fruSerialNumberName}, $result->{fruInformationStatus}, $instance, 
            )
        );

        my $exit = $self->get_severity(label => 'default.status', section => 'fru.status', value => $result->{fruInformationStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Fru '%s' status is '%s'", $result->{fruSerialNumberName}, $result->{fruInformationStatus})
            );
        }
    }
}

1;
