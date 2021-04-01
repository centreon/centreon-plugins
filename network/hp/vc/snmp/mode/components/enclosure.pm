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

package network::hp::vc::snmp::mode::components::enclosure;

use strict;
use warnings;
use network::hp::vc::snmp::mode::components::resources qw($map_managed_status $map_reason_code);

my $mapping = {
    vcEnclosureName => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.2.1.1.2' },
    vcEnclosureManagedStatus => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.2.1.1.3', map => $map_managed_status },
    vcEnclosureReasonCode => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.2.1.1.9', map => $map_reason_code },
};
my $oid_vcEnclosureEntry = '.1.3.6.1.4.1.11.5.7.5.2.1.1.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_vcEnclosureEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking enclosures");
    $self->{components}->{enclosure} = { name => 'enclosures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'enclosure'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vcEnclosureEntry}})) {
        next if ($oid !~ /^$mapping->{vcEnclosureManagedStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_vcEnclosureEntry}, instance => $instance);

        next if ($self->check_filter(section => 'enclosure', instance => $instance));
        $self->{components}->{enclosure}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("enclosure '%s' status is '%s' [instance: %s, reason: %s].",
                                    $result->{vcEnclosureName}, $result->{vcEnclosureManagedStatus},
                                    $instance, $result->{vcEnclosureReasonCode}
                                    ));
        my $exit = $self->get_severity(section => 'enclosure', label => 'default', value => $result->{vcEnclosureManagedStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Enclosure '%s' status is '%s'",
                                                             $result->{vcEnclosureName}, $result->{vcEnclosureManagedStatus}));
        }
    }
}

1;