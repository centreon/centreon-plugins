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

package os::solaris::local::mode::lomv120components::sf;

use strict;
use warnings;
use centreon::plugins::misc;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking system flag");
    $self->{components}->{sf} = {name => 'system flag', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sf'));
    
    #System status flags:
    # 1        SCSI-Term status=ok
    # 2             USB0 status=ok
    # 3             USB1 status=ok
    return if ($self->{stdout} !~ /^System status flags:(.*)/ims);
    
    my @content = split(/\n/, $1);
    shift @content;
    foreach my $line (@content) {
        $line = centreon::plugins::misc::trim($line);
        next if ($line !~ /^\s*(\S+).*?status=(.*)/);
        my ($instance, $status) = ($1, $2);
        
        next if ($self->check_filter(section => 'sf', instance => $instance));
        $self->{components}->{sf}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "system flag '%s' status is %s.",
                $instance, $status
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'sf', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("system flag '%s' status is %s",
                                                             $instance, $status));
        }
    }
}

1;
