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

package hardware::devices::video::axis::snmp::mode::components::video;

use strict;
use warnings;

my %map_video_status = (
    1 => 'signalOk',
    2 => 'noSignal',
);

my $mapping = {
    axisVideoState => { oid => '.1.3.6.1.4.1.368.4.1.4.1.2', map => \%map_video_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{axisVideoState}->{oid} };
}

sub check {
    my ($self) = @_;

    
    $self->{output}->output_add(long_msg => "Checking Video Signal");
    $self->{components}->{video} = {name => 'video', total => 0, skip => 0};
    return if ($self->check_filter(section => 'video'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{axisVideoState}->{oid}}})) {
        next if ($oid !~ /^$mapping->{axisVideoState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{axisVideoState}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'video', instance => $instance));
        $self->{components}->{video}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("video '%s' state is %s [instance: %s].",
                                    $instance, $result->{axisVideoState}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'video', value => $result->{axisVideoState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("video '%s' state is %s", 
                                                             $instance, $result->{axisVideoState}));
        }
    }
}

1;