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

package centreon::common::polycom::endpoint::snmp::mode::components::global;

use strict;
use warnings;
use centreon::common::polycom::endpoint::snmp::mode::components::resources qw($map_status);

my $mapping = {
    hardwareOverallStatus   => { oid => '.1.3.6.1.4.1.13885.101.1.3.1', map => $map_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{hardwareOverallStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking global");
    $self->{components}->{global} = {name => 'global', total => 0, skip => 0};
    return if ($self->check_filter(section => 'global'));

    return if (!defined($self->{results}->{ $mapping->{hardwareOverallStatus}->{oid} }) ||
        scalar(keys %{$self->{results}->{ $mapping->{hardwareOverallStatus}->{oid} }}) <= 0);

    my $instance = '0';
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{hardwareOverallStatus}->{oid} }, instance => $instance);

    return if ($self->check_filter(section => 'global', instance => $instance));
    $self->{components}->{global}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            'overall global status is %s [instance: %s]',
            $result->{hardwareOverallStatus}, $instance
        )
    );
    my $exit = $self->get_severity(section => 'global', label => 'default', value => $result->{hardwareOverallStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity =>  $exit,
            short_msg =>
                sprintf('Overall global status is %s', $result->{hardwareOverallStatus}
            )
        );
    }
}

1;
