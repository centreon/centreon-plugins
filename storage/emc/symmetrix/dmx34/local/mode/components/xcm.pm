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

package storage::emc::symmetrix::dmx34::local::mode::components::xcm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#     --------------[ XCM Information ]--------------
# 
#XCM/ECM/CCM status
#    XCM0  XCM1
#    EMUL  EMUL
# 
#Message Bus status

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking xcm");
    $self->{components}->{xcm} = {name => 'xcm', total => 0, skip => 0};
    return if ($self->check_filter(section => 'xcm'));
    
    if ($self->{content_file_health} !~ /----\[ XCM Information(.*?)----\[/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find xcm');
        return ;
    }
    
    my $content = $1;
    
    if ($content =~ /XCM\/ECM\/CCM status\s*\n\s*(.*?)\n\s*(.*?)\n\s*\n/msig) {
        my @names = split /\s+/, $1;
        my @status = split /\s+/, $2;
        
        my $i = -1;
        foreach my $name (@names) {
            $i++;
            my $instance = $name;
            my $state = $status[$i];
            
            next if ($self->check_filter(section => 'xcm', instance => $instance));
            $self->{components}->{xcm}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("xcm '%s' state is '%s'", 
                                                            $instance, $state));
            my $exit = $self->get_severity(section => 'xcm', value => $state);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("XCM '%s' state is '%s'", 
                                                                 $instance, $state));
            }
        }
    }
}

1;
