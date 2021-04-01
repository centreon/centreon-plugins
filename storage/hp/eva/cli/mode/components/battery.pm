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

package storage::hp::eva::cli::mode::components::battery;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    
    $self->{ssu_commands}->{'ls controller full xml'} = 1;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cache batteries");
    $self->{components}->{battery} = {name => 'cache battery', total => 0, skip => 0};
    return if ($self->check_filter(section => 'battery'));
    
    # <object>
    #    <objecttype>controller</objecttype>
    #    <objectname>\Hardware\Rack 1\Controller Enclosure 7\Controller B</objectname>
    #    <cachebattery>
    #         <operationalstate>good</operationalstate>
    foreach my $object (@{$self->{xml_result}->{object}}) {
        next if ($object->{objecttype} ne 'controller');
        
        $object->{objectname} =~ s/\\/\//g;
        my $instance = $object->{objectname};
            
        next if ($self->check_filter(section => 'battery', instance => $instance));

        $self->{components}->{battery}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("cache battery '%s' status is '%s' [instance = %s]",
                                    $instance, $object->{cachebattery}->{operationalstate}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default', section => 'battery', value => $object->{cachebattery}->{operationalstate});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Cache battery '%s' status is '%s'", $instance, $object->{cachebattery}->{operationalstate}));
        }
    }
}

1;
