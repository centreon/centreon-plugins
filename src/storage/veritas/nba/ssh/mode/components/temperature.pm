#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package storage::veritas::nba::ssh::mode::components::temperature;

use strict;
use warnings;
use centreon::plugins::misc;

sub load {}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperature', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    while ($self->{result} =~ /Hardware\s+monitor\s+information\s+(.*?)(?=\s+Hardware monitor information|\Z$)/msg) {
        my $part = $1;

        next if ($part !~ /StorageShelf\s+(\d+)\s+Temperature\s+Information/i);
        my $shelf = $1;
  
        while ($part =~ /^.*?Enclosure(.*?)Temperature\s+(.*?)\s+\|(.*?)Degrees\s+Celsius.*?\|.*?\|(.*?)\|/mig) {            
            my ($enclosure, $temp, $read, $state) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4));
            my $instance = 'shelf' . $shelf . '.' . $enclosure . '.' . $temp;

            next if ($self->check_filter(section => 'temperature', instance => $instance));
            $self->{components}->{temperature}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "temperature '%s' shelf '%s' enclosure '%s' state is %s [current: %s]",
                    $temp,
                    $shelf,
                    $enclosure,
                    $state,
                    $read
                )
            );
            my $exit = $self->get_severity(label => 'default', section => 'temperature', instance => $instance, value => $state);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity =>  $exit,
                    short_msg => sprintf(
                        "temperature '%s' shelf '%s' enclosure '%s' state is %s",
                        $temp, $shelf, $enclosure, $state
                    )
                );
            }
            
            next if ($read !~ /[0-9]+/);

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $read);

            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "temperature '%s' shelf '%s' enclosure '%s' is %s degree centigrade",
                        $temp,
                        $shelf,
                        $enclosure,
                        $read
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.temperature.celsius',
                unit => 'C',
                instances => ['shelf' . $shelf, $enclosure, $temp],
                value => $read,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
