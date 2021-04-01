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

package centreon::common::ibm::tapelibrary::snmp::mode::components::chassis;

use strict;
use warnings;
use centreon::common::ibm::tapelibrary::snmp::mode::components::resources qw($map_operational);

my $mapping = {
    subChassis_OperationalStatus   => { oid => '.1.3.6.1.4.1.14851.3.1.4.10.1.10', map => $map_operational },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{subChassis_OperationalStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking chassis");
    $self->{components}->{chassis} = {name => 'chassis', total => 0, skip => 0};
    return if ($self->check_filter(section => 'chassis'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{subChassis_OperationalStatus}->{oid}}})) {
        $oid =~ /^$mapping->{subChassis_OperationalStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{subChassis_OperationalStatus}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'chassis', instance => $instance));
        $self->{components}->{chassis}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("chassis '%s' status is '%s' [instance: %s].",
                                    $instance, $result->{subChassis_OperationalStatus},
                                    $instance
                                    ));
        my $exit = $self->get_severity(label => 'operational', section => 'chassis', value => $result->{subChassis_OperationalStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("chassis '%s' status is '%s'",
                                                             $instance, $result->{subChassis_OperationalStatus}));
        }
    }
}

1;