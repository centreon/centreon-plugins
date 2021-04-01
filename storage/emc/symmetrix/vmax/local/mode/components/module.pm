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

package storage::emc::symmetrix::vmax::local::mode::components::module;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#Modules status (alarms): OK
#+-------------------------------------------------------------------+-----------+----------+--------+------------+
#| Module                                                            | Ctrl dirs | Rep dirs | Status | Rel Status |
#+-------------------------------------------------------------------+-----------+----------+--------+------------+
#| Engine 4                                                          | 07A,08A   | 07A,08A  | OK     |            |
#| Engine SPS 4A                                                     | 07A       | 07A      | OK     |            |
#| Engine SPS 4B                                                     | 08A       | 08A      | OK     |            |
#| Engine Power Supply A of ES-4                                     | 07A       | 07A      | OK     |            |
#+-------------------------------------------------------------------+-----------+----------+--------+------------+
#| Module                                                            | Ctrl dirs | Rep dirs | Status | Rel Status |
#+-------------------------------------------------------------------+-----------+----------+--------+------------+

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking modules");
    $self->{components}->{module} = {name => 'modules', total => 0, skip => 0};
    return if ($self->check_filter(section => 'module'));
    
    if ($self->{content_file_health_env} !~ /Ethernet cabling.*?Modules status.*?---------.*?Module.*?---------.*?\n(.*?\n)\+---------/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find modules');
        return ;
    }
    
    my $content = $1;
    while ($content =~ /^\|(.*?)\|.*?\|.*?\|(.*?)\|.*?\n/msig) {
        my ($module, $status) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));

        next if ($self->check_filter(section => 'module', instance => $module));
        $self->{components}->{module}->{total}++;
            
        $self->{output}->output_add(long_msg => sprintf("module '%s' status is '%s'", 
                                                        $module, $status));
        my $exit = $self->get_severity(label => 'default', section => 'module', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Module '%s' status is '%s'", 
                                                             $module, $status));
        }
    }
}

1;
