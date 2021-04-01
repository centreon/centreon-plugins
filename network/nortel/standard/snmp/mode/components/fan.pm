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

package network::nortel::standard::snmp::mode::components::fan;

use strict;
use warnings;
use network::nortel::standard::snmp::mode::components::resources qw($map_fan_status);

my $mapping = {
    rcChasFanOperStatus         => { oid => '.1.3.6.1.4.1.2272.1.4.7.1.1.2', map => $map_fan_status },
    rcChasFanAmbientTemperature => { oid => '.1.3.6.1.4.1.2272.1.4.7.1.1.3' },
};
my $oid_rcChasFanEntry = '.1.3.6.1.4.1.2272.1.4.7.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rcChasFanEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rcChasFanEntry}})) {
        next if ($oid !~ /^$mapping->{rcChasFanOperStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rcChasFanEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance: %s, value: %s].",
                                    $instance, $result->{rcChasFanOperStatus},
                                    $instance, $result->{rcChasFanAmbientTemperature}
                                    ));
        my $exit = $self->get_severity(section => 'fan', instance => $instance, value => $result->{rcChasFanOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'",
                                                             $instance, $result->{rcChasFanOperStatus}));
        }
        
        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'fan.temperature', instance => $instance, value => $result->{rcChasFanAmbientTemperature});        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Fan temperature '%s' is %s degree centigrade", $instance, $result->{rcChasFanAmbientTemperature}));
        }
        $self->{output}->perfdata_add(
            label => 'fan_temp', unit => 'C',
            nlabel => 'hardware.fan.temperature.celsius',
            instances => $instance,
            value => $result->{rcChasFanAmbientTemperature},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
