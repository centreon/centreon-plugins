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

package storage::veritas::nba::ssh::mode::components::psu;

use strict;
use warnings;
use centreon::plugins::misc;

sub load {}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    while ($self->{result} =~ /Hardware\s+monitor\s+information\s+(.*?)(?=\s+Hardware monitor information|\Z$)/msg) {
        my $part = $1;

        next if ($part !~ /StorageShelf\s+(\d+)\s+Power\s+Supply\s+Information/i);
        my $shelf = $1;
  
        while ($part =~ /^.*?Enclosure(.*?)Power\s+Supply\s+(.*?)\s+\|.*?\|(.*?)\|/mig) {            
            my ($enclosure, $psu, $state) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($3));
            my $instance = 'shelf' . $shelf . '.' . $enclosure . '.' . $psu;

            next if ($self->check_filter(section => 'psu', instance => $instance));
            $self->{components}->{psu}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "power supply '%s' shelf '%s' enclosure '%s' state is %s",
                    $psu,
                    $shelf,
                    $enclosure,
                    $state
                )
            );
            my $exit = $self->get_severity(label => 'default', section => 'psu', instance => $instance, value => $state);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity =>  $exit,
                    short_msg => sprintf(
                        "power supply '%s' shelf '%s' enclosure '%s' state is %s",
                        $psu, $shelf, $enclosure, $state
                    )
                );
            }
        }
    }
}

1;
