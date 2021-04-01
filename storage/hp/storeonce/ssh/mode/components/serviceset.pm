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

package storage::hp::storeonce::ssh::mode::components::serviceset;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    
    #Service Set 1         Status
    #-------------         -------
    #Overall             : Running
    #StoreOnce Subsystem : Running
    #Virtual Tape        : Running
    #NAS                 : Running
    #StoreOnce Catalyst  : Running
    #Replication         : Running
    #Housekeeping        : Running
    #
    #Service Set 2         Status
    #-------------         -------
    #Overall             : Running
    #StoreOnce Subsystem : Running
    #Virtual Tape        : Running
    #NAS                 : Running
    #StoreOnce Catalyst  : Running
    #Replication         : Running
    #Housekeeping        : Running

    push @{$self->{commands}}, "serviceset show status";
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking service sets");
    $self->{components}->{serviceset} = {name => 'service sets', total => 0, skip => 0};
    return if ($self->check_filter(section => 'serviceset'));

    return if ($self->{result} !~ /[>#]\s*serviceset show status(.*?)\n[>#]/msi);
    my $content = $1;
    
    while ($content =~ /^Service Set (\d+).*?\n(.*?)\n\s*?\n/msgi) {
        my ($num, $details) = ($1, $2);
        
        while ($details =~ /^([^\n]+?):\s*(.*?)\n/msgi) {
            my ($instance, $status) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));
                    
            next if ($self->check_filter(section => 'serviceset', instance => $num . '.' . $instance));
            $self->{components}->{serviceset}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("service set '%s' %s status is '%s' [instance: %s].",
                                        $num, $instance, $status,
                                        $num . '.' . $instance
                                        ));
            my $exit = $self->get_severity(section => 'serviceset', instance => $num . '.' . $instance, value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity =>  $exit,
                                            short_msg => sprintf("service set '%s' %s status is '%s'",
                                                                 $num, $instance, $status));
            }
        }
    }
}

1;