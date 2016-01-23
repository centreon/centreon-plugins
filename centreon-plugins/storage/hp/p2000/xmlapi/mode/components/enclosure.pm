#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::hp::p2000::xmlapi::mode::components::enclosure;

use strict;
use warnings;

my @conditions = (
    ['^degraded$' => 'WARNING'],
    ['^failed$' => 'CRITICAL'],
    ['^(unknown|not available)$' => 'UNKNOWN'],
);

my %health = (
    0 => 'ok',
    1 => 'degraded',
    2 => 'failed',
    3 => 'unknown',
    4 => 'not available',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking enclosures");
    $self->{components}->{enclosure} = {name => 'enclosures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'enclosure'));
    
    my $results = $self->{p2000}->get_infos(cmd => 'show enclosures', 
                                            base_type => 'enclosures',
                                            key => 'durable-id',
                                            properties_name => '^health-numeric|health-reason$');
    foreach my $enc_id (keys %$results) {
        next if ($self->check_exclude(section => 'enclosure', instance => $enc_id));
        $self->{components}->{enclosure}->{total}++;
        
        my $state = $health{$results->{$enc_id}->{'health-numeric'}};
        
        $self->{output}->output_add(long_msg => sprintf("enclosure '%s' status is %s.",
                                                        $enc_id, $state)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("enclosure '%s' status is %s (reason: %s)",
                                                        $enc_id, $state, $health{$results->{$enc_id}->{'health-reason'}}));
                last;
            }
        }
    }
}

1;