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

package storage::dell::me4::restapi::mode::components::fru;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{json_results}->{frus} = $self->{custom}->request_api(method => 'GET', url_path => '/api/show/frus');
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking FRUs");
    $self->{components}->{fru} = {name => 'frus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fru'));
    return if (!defined($self->{json_results}->{frus}));
    
    foreach my $result (@{$self->{json_results}->{frus}->{'enclosure-fru'}}) {
        my $instance = $result->{name};
        
        next if ($self->check_filter(section => 'fru', instance => $instance));

        $self->{components}->{fru}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("FRU '%s' status is '%s'",
                                    $result->{name}, $result->{'fru-status'}));
        
        my $exit1 = $self->get_severity(section => 'fru', value => $result->{'fru-status'});
        if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit1,
                                        short_msg => sprintf("FRU '%s' status is '%s'", $result->{name}, $result->{'fru-status'}));
        }
    }
}

1;
