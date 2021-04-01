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

package storage::emc::symmetrix::dmx34::local::mode::components::fru;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#FRU status (alarms) table:
#
#+---------------------+--------------------+-----------+
#| Description         | FRU/Alarm Status   | Comm.     |
#+---------------------+--------------------+-----------+
#| Dir 01              | OK                 | 01A       |
#| Dir 02              | OK                 | 02A       |
#...
#| Backplane           | OK                 | 01A,16A   |
#+---------------------+--------------------+-----------+
#| Description         | FRU/Alarm Status   | Comm.     |
#+---------------------+--------------------+-----------+
#
#
#Analog readings:

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking frus");
    $self->{components}->{fru} = {name => 'frus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fru'));
    
    if ($self->{content_file_health_env} !~ /FRU status .*? table:.*?---------.*?Description.*?---------.*?\n(.*?\n)\+---------/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find frus');
        return ;
    }
    
    my $content = $1;
    while ($content =~ /^\|(.*?)\|(.*?)\|.*?\n/msig) {
        my ($fru, $status) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));

        next if ($self->check_filter(section => 'fru', instance => $fru));
        $self->{components}->{fru}->{total}++;
            
        $self->{output}->output_add(long_msg => sprintf("fru '%s' status is '%s'", 
                                                        $fru, $status));
        my $exit = $self->get_severity(section => 'fru', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fru '%s' status is '%s'", 
                                                             $fru, $status));
        }
    }
}

1;
