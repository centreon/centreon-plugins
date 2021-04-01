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

package hardware::devices::video::axis::snmp::mode::components::audio;

use strict;
use warnings;

my %map_audio_status = (
    1 => 'signalOk',
    2 => 'noSignal',
);

my $mapping = {
    axisAudioState => { oid => '.1.3.6.1.4.1.368.4.1.5.1.2', map => \%map_audio_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{axisAudioState}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking audio Signal");
    $self->{components}->{audio} = {name => 'audio', total => 0, skip => 0};
    return if ($self->check_filter(section => 'audio'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{axisAudioState}->{oid}}})) {
        next if ($oid !~ /^$mapping->{axisAudioState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{axisAudioState}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'audio', instance => $instance));
        $self->{components}->{audio}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("audio '%s' state is %s [instance: %s].",
                                    $instance, $result->{axisAudioState}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'audio', value => $result->{axisAudioState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("audio '%s' state is %s", 
                                                             $instance, $result->{axisAudioState}));
        }
    }
}

1;