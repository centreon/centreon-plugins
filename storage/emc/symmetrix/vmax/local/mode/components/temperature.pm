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

package storage::emc::symmetrix::vmax::local::mode::components::temperature;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#Temperatures check: OK
#
#+-------------------+------------+------------+------------------+--------+
#| Module            | Temp  [°C] | Temp  [°F] | High Limit  [°C] | Status |
#+-------------------+------------+------------+------------------+--------+
#| ES-PWS-A ES-4     |      24    |      75    |                  | OK     |
#| ES-PWS-B ES-4     |      22    |      71    |                  | OK     |
#| DIR-7 ES-4        |      34    |      93    |                  | OK     |
#| DIR-8 ES-4        |      36    |      96    |                  | OK     |
#| DIMM-0 DIR-7 ES-4 |      43    |     109    |      88          | OK     |
#| DIMM-1 DIR-7 ES-4 |      48    |     118    |      91          | OK     |
#+-------------------+------------+------------+------------------+--------+
#| Module            | Temp  [°C] | Temp  [°F] | High Limit  [°C] | Status |
#+-------------------+------------+------------+------------------+--------+

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    if ($self->{content_file_health_env} !~ /Ethernet cabling.*?Temperatures check.*?---------.*?Module.*?---------.*?\n(.*?\n)\+---------/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find temperatures');
        return ;
    }
    
    my $content = $1;
    while ($content =~ /^\|(.*?)\|.*?\|.*?\|.*?\|(.*?)\|.*?\n/msig) {
        my ($temperature, $status) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));

        next if ($self->check_filter(section => 'temperature', instance => $temperature));
        $self->{components}->{temperature}->{total}++;
            
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s'", 
                                                        $temperature, $status));
        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", 
                                                             $temperature, $status));
        }
    }
}

1;
