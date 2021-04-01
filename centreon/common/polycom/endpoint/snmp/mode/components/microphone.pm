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

package centreon::common::polycom::endpoint::snmp::mode::components::microphone;

use strict;
use warnings;
use centreon::common::polycom::endpoint::snmp::mode::components::resources qw($map_status);

my $mapping = {
    hardwareMicrophoneMicrophonesName   => { oid => '.1.3.6.1.4.1.13885.101.1.3.5.2.1.2' },
    hardwareMicrophoneMicrophonesStatus => { oid => '.1.3.6.1.4.1.13885.101.1.3.5.2.1.3', map => $map_status },
};
my $oid_hardwareMicrophoneMicrophonesEntry = '.1.3.6.1.4.1.13885.101.1.3.5.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hardwareMicrophoneMicrophonesEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking microphones");
    $self->{components}->{microphone} = {name => 'microphones', total => 0, skip => 0};
    return if ($self->check_filter(section => 'microphone'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hardwareMicrophoneMicrophonesEntry}})) {
        next if ($oid !~ /^$mapping->{hardwareMicrophoneMicrophonesStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hardwareMicrophoneMicrophonesEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'microphone', instance => $instance));
        $self->{components}->{microphone}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "microphone '%s' status is '%s' [instance = %s]",
                $result->{hardwareMicrophoneMicrophonesName},
                $result->{hardwareMicrophoneMicrophonesStatus},
                $instance, 
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'microphone', instance => $instance, value => $result->{hardwareMicrophoneMicrophonesStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Microphone '%s' status is '%s'",
                    $result->{hardwareMicrophoneMicrophonesName},
                    $result->{hardwareMicrophoneMicrophonesStatus}
                )
            );
        }
    }
}

1;
