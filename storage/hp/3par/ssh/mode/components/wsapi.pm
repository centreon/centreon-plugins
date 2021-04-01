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

package storage::hp::3par::ssh::mode::components::wsapi;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    #-Service- -State- -HTTP_State- HTTP_Port -HTTPS_State- HTTPS_Port -Version- -----------------API_URL------------------
    #Enabled   Active  Disabled          8008 Enabled             8080 1.5.3     https://xxxx:8080/api/v1
    push @{$self->{commands}}, 'echo "===showwsapi==="', 'showwsapi';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking wsapi");
    $self->{components}->{wsapi} = { name => 'wsapi', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'wsapi'));

    return if ($self->{results} !~ /===showwsapi===.*?\n(.*?)(===|\Z)/msi);
    my @results = split /\n/, $1;

    my $instance = 0;
    foreach (@results) {
        next if (!/^(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+\S+/);
        $instance++;
        my ($service_status, $service_state, $http_state,
            $http_port, $https_state, $https_port) = ($1, $2, $3, $4, $5, $6);

        next if ($self->check_filter(section => 'wsapi', instance => $instance));
        $self->{components}->{wsapi}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("wsapi service state is '%s' [status: '%s'] [HTTP on port %d is %s] [HTTPS on port %d is %s] [instance: %s]",
                                    $service_state, $service_status, $http_port, $http_state, $https_port ,$https_state, $instance)
                                    );
        my $exit = $self->get_severity(label => 'default.state', section => 'wsapi.state', value => $service_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("wsapi service state is '%s' [instance: %s]",
                                                             $service_state, $instance));
        }

        $exit = $self->get_severity(label => 'default.status', section => 'wsapi.status', value => $service_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("wsapi service status is '%s' [instance: %s]",
                                                             $service_status, $instance));
        }
    }
}

1;
