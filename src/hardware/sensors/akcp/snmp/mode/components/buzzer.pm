#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package hardware::sensors::akcp::snmp::mode::components::buzzer;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default1_status);

my $mapping = {
    buzzerDescription  => { oid => '.1.3.6.1.4.1.3854.3.5.11.1.2' },
    buzzerStatus       => { oid => '.1.3.6.1.4.1.3854.3.5.11.1.6', map => \%map_default1_status },
};
my $oid_buzzerEntry = '.1.3.6.1.4.1.3854.3.5.11.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_buzzerEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking buzzers");
    $self->{components}->{buzzer} = {name => 'buzzers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'buzzer'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_buzzerEntry}})) {
        next if ($oid !~ /^$mapping->{buzzerStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_buzzerEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'buzzer', instance => $instance));
        $self->{components}->{buzzer}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("buzzer '%s' status is '%s' [instance = %s]",
                                    $result->{buzzerDescription}, $result->{buzzerStatus}, $instance,
                                    ));
        
        my $exit = $self->get_severity(label => 'default1', section => 'buzzer', value => $result->{buzzerStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Buzzer '%s' status is '%s'", $result->{buzzerDescription}, $result->{buzzerStatus}));
        }
    }
}

1;
