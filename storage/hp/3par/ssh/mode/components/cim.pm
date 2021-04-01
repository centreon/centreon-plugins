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

package storage::hp::3par::ssh::mode::components::cim;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    #-Service- -State- --SLP-- SLPPort -HTTP-- HTTPPort -HTTPS- HTTPSPort PGVer CIMVer
    #Enabled   Active  Enabled     427 Enabled     5988 Enabled      5989 2.9.1 3.2.2 
    push @{$self->{commands}}, 'echo "===showcim==="', 'showcim';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cim");
    $self->{components}->{cim} = { name => 'cim', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'cim'));

    return if ($self->{results} !~ /===showcim===.*?\n(.*?)(===|\Z)/msi);
    my @results = split /\n/, $1;

    my $instance = 0;
    foreach (@results) {
        next if (!/^(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+\S+/);
        $instance++;
        my ($service_status, $service_state, $slp_state, $slp_port, $http_state,
            $http_port, $https_state, $https_port) = ($1, $2, $3, $4, $5, $6, $7, $8);

        next if ($self->check_filter(section => 'cim', instance => $instance));
        $self->{components}->{cim}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("cim service state is '%s' [status: '%s'] [SLP on port %d is %s] [HTTP on port %d is %s] [HTTPS on port %d is %s] [instance: %s]",
                                    $service_state, $service_status, $slp_port, $slp_state, $http_port, $http_state, $https_port ,$https_state, $instance)
                                    );
        my $exit = $self->get_severity(label => 'default.state', section => 'cim.state', value => $service_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("cim service state is '%s' [instance: %s]",
                                                             $service_state, $instance));
        }

        $exit = $self->get_severity(label => 'default.status', section => 'cim.status', value => $service_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("cim service status is '%s' [instance: %s]",
                                                             $service_status, $instance));
        }
    }
}

1;
