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

package storage::dell::me4::restapi::mode::components::fan;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{json_results}->{fans} = $self->{custom}->request_api(method => 'GET', url_path => '/api/show/fans');
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    return if (!defined($self->{json_results}->{fans}));
    
    foreach my $result (@{$self->{json_results}->{fans}->{fan}}) {
        my $instance = $result->{'durable-id'};
        
        next if ($self->check_filter(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is '%s', health is '%s' [instance = %s] [speed = %s rpm]",
                                    $result->{name}, $result->{status}, $result->{health}, $instance,
                                    $result->{speed}));
        
        my $exit1 = $self->get_severity(section => 'fan', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit1,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $result->{name}, $result->{status}));
        }
        my $exit2 = $self->get_severity(section => 'fan', value => $result->{health});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Fan '%s' health is '%s'", $result->{name}, $result->{health}));
        }
        
        next if ($result->{speed} !~ /[0-9]/);
        my ($exit3, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{speed});        
        if (!$self->{output}->is_status(value => $exit3, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit3,
                                        short_msg => sprintf("Fan '%s' speed is %s rpm", $result->{name}, $result->{speed}));
        }
        $self->{output}->perfdata_add(
            label => 'speed', unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $instance,
            value => $result->{speed},
            warning => $warn,
            critical => $crit, 
            min => 0
        );
    }
}

1;
