#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package storage::hp::p2000::xmlapi::mode::components::fru;

use strict;
use warnings;

my @conditions = (
    ['^absent$' => 'WARNING'],
    ['^fault$' => 'CRITICAL'],
    ['^not available$' => 'UNKNOWN'],
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking frus");
    $self->{components}->{fru} = {name => 'frus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fru'));
    
    my $results = $self->{p2000}->get_infos(cmd => 'show frus', 
                                            base_type => 'enclosure-fru',
                                            key => 'part-number', 
                                            properties_name => '^(fru-status|fru-location)$');
    foreach my $part_number (keys %$results) {
        my $instance = $results->{$part_number}->{'fru-location'};
    
        next if ($self->check_exclude(section => 'fru', instance => $instance));
        $self->{components}->{fru}->{total}++;
        
        my $state = $results->{$part_number}->{'fru-status'};
        
        $self->{output}->output_add(long_msg => sprintf("fru '%s' status is %s.",
                                                        $instance, $state)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("fru '%s' status is %s",
                                                        $instance, $state));
                last;
            }
        }
    }
}

1;