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

package storage::emc::symmetrix::vmax::local::mode::components::voltage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#Voltages check: OK
sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltage");
    $self->{components}->{voltage} = {name => 'voltage', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));
    
    if ($self->{content_file_health_env} !~ /Voltages check:(.*?)\n/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find voltage');
        return ;
    }
    
    my $content = centreon::plugins::misc::trim($1);    
    $self->{components}->{voltage}->{total}++;
    
    $self->{output}->output_add(long_msg => sprintf("voltage status is '%s'", 
                                                    $content));
    my $exit = $self->get_severity(label => 'default', section => 'voltage', value => $content);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Voltage status is '%s'", 
                                                         $content));
    }
}

1;
