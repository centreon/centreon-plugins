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

package apps::vmware::wsman::mode::components::cim_memory;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;
    
    my $result = $self->{wsman}->request(uri => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_Memory', dont_quit => 1);
    
    $self->{output}->output_add(long_msg => "Checking cim memories");
    $self->{components}->{cim_memory} = {name => 'memories', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cim_memory') || !defined($result));

    foreach (@{$result}) {
        my $instance = defined($_->{Name}) && $_->{Name} ne '' ? $_->{Name} : $_->{ElementName};
        
        next if ($self->check_filter(section => 'cim_memory', instance => $instance));
        my $status = $self->get_status(entry => $_);
        if (!defined($status)) {
            $self->{output}->output_add(long_msg => sprintf("skipping memory '%s' : no status", $_->{ElementName}), debug => 1);
            next;
        }
        
        $self->{components}->{cim_memory}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Memory '%s' status is '%s' [instance: %s].",
                                    $_->{ElementName}, $status,
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'cim_memory', label => 'default', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Memory '%s' status is '%s'",
                                                             $_->{ElementName}, $status));
        }
    }
}

1;
