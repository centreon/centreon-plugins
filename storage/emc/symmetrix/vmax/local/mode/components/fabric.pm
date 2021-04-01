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

package storage::emc::symmetrix::vmax::local::mode::components::fabric;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#Fabric system: OK
#
#+-------------------------------------------------+---------------------------------+
#| Item                                            | Status                          |
#+-------------------------------------------------+---------------------------------+
#| Fabric System General Status                    | OK                              |
#|   Usage Mode                                    | Full usage - BOSCO and Ethernet |
#|   Initialization Status                         | OK                              |
#|   Configuration Status                          | OK                              |
#|   Fabric A Availability                         | Available                       |
#|   Fabric B Availability                         | Available                       |
#| Directors' Fabric Links Status                  | OK                              |
#|   Dir 7 (RIO 0x0C)                              | All links are up                |
#|     Link A status                               | Up                              |
#|     Link B status                               | Up                              |
#+-------------------------------------------------+---------------------------------+
#| Item                                            | Status                          |
#+-------------------------------------------------+---------------------------------+

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fabrics");
    $self->{components}->{fabric} = {name => 'fabrics', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fabric'));
    
    if ($self->{content_file_health_env} !~ /Ethernet cabling.*?Fabric system.*?---------.*?Item.*?---------.*?\n(.*?\n)\+---------/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find fabrics');
        return ;
    }
    
    my $content = $1;
    
    my $total_components = 0;
    my @stack = ({ indent => 0, long_instance => '' });
    while ($content =~ /^\|([ \t]+)(.*?)\|(.*?)\|\n/msig) {
        my ($indent, $name, $status) = (length($1), centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($3));
        
        pop @stack while ($indent <= $stack[$#stack]->{indent});
        
        my $long_instance = $stack[$#stack]->{long_instance} . '>' . $name;
        if ($indent > $stack[$#stack]->{indent}) {
            push @stack, { indent => $indent, 
                           long_instance => $stack[$#stack]->{long_instance} . '>' . $name };
        }
        
        next if ($name !~ /status/i);
        
        next if ($self->check_filter(section => 'fabric', instance => $long_instance));
        $self->{components}->{fabric}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fabric '%s' status is '%s'", 
                                                        $long_instance, $status));
        my $exit = $self->get_severity(label => 'default', section => 'fabric', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fabric '%s' status is '%s'", 
                                                             $long_instance, $status));
        }
    }
}

1;
