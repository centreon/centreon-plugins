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

package storage::emc::symmetrix::vmax::local::mode::components::cabling;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#Ethernet cabling: OK
#
#+--------------------------------------------------+--------+----------------------+--------------------+----------------------+----------------------+------------+--------------+
#| Cable Name                                       | Status | Expected 'From' Port | Actual 'From' Port | Expected 'To' Port   | Actual 'To' Port     | Error Code | Error string |
#+--------------------------------------------------+--------+----------------------+--------------------+----------------------+----------------------+------------+--------------+
#| Cable from SRV A Adapter to MM-A ES-4 Lower port | OK     | SRV A Adapter        | SRV A Adapter      | MM-A ES-4 Lower port | MM-A ES-4 Lower port | None       |              |
#| Cable from SRV B Adapter to MM-B ES-4 Lower port | OK     | SRV B Adapter        | SRV B Adapter      | MM-B ES-4 Lower port | MM-B ES-4 Lower port | None       |              |
#+--------------------------------------------------+--------+----------------------+--------------------+----------------------+----------------------+------------+--------------+
#| Cable Name                                       | Status | Expected 'From' Port | Actual 'From' Port | Expected 'To' Port   | Actual 'To' Port     | Error Code | Error string |
#+--------------------------------------------------+--------+----------------------+--------------------+----------------------+----------------------+------------+--------------+

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cabling");
    $self->{components}->{cabling} = {name => 'cabling', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cabling'));
    
    if ($self->{content_file_health_env} !~ /Ethernet cabling.*?Ethernet cabling.*?---------.*?Cable Name.*?---------.*?\n(.*?\n)\+---------/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find cabling');
        return ;
    }
    
    my $content = $1;
    while ($content =~ /^\|(.*?)\|(.*?)\|.*?\n/msig) {
        my ($cabling, $status) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));

        next if ($self->check_filter(section => 'cabling', instance => $cabling));
        $self->{components}->{cabling}->{total}++;
            
        $self->{output}->output_add(long_msg => sprintf("cabling '%s' status is '%s'", 
                                                        $cabling, $status));
        my $exit = $self->get_severity(label => 'default', section => 'cabling', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Cabling '%s' status is '%s'", 
                                                             $cabling, $status));
        }
    }
}

1;
