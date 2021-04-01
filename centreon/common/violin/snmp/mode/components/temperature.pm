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

package centreon::common::violin::snmp::mode::components::temperature;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_chassisSystemTempAmbient = '.1.3.6.1.4.1.35897.1.2.2.3.17.1.21';
my $oid_chassisSystemTempController = '.1.3.6.1.4.1.35897.1.2.2.3.17.1.21';
my $oid_arrayVimmEntry_temp = '.1.3.6.1.4.1.35897.1.2.2.3.16.1.12';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_arrayVimmEntry_temp }, { oid => $oid_chassisSystemTempAmbient }, 
        { oid => $oid_chassisSystemTempController };
}

sub temperature {
    my ($self, %options) = @_;
    my $oid = $options{oid};
    
    $options{oid} =~ /^$options{oid_short}\.(.*)$/;
    my ($dummy, $array_name, $extra_name) = $self->convert_index(value => $1);
    my $instance = $array_name . '-' . (defined($extra_name) ? $extra_name : $options{extra_instance});
    
    my $temperature = $options{value};

    return if ($self->check_filter(section => 'temperature', instance => $instance));
        
    $self->{components}->{temperature}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("Temperature '%s' is %s degree centigrade.",
                                $instance, $temperature));
    my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $temperature);
    $self->{output}->perfdata_add(
        label => 'temp', unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        instances => $instance,
        value => $temperature,
        warning => $warn,
        critical => $crit
    );
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Temperature '%s' is %s degree centigrade", $instance, $temperature));
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid (keys %{$self->{results}->{$oid_chassisSystemTempAmbient}}) {
        temperature($self, oid => $oid, oid_short => $oid_chassisSystemTempAmbient, value => $self->{results}->{$oid_chassisSystemTempAmbient}->{$oid},
            extra_instance => 'ambient');
    }
    foreach my $oid (keys %{$self->{results}->{$oid_chassisSystemTempController}}) {
        temperature($self, oid => $oid, oid_short => $oid_chassisSystemTempController, value => $self->{results}->{$oid_chassisSystemTempController}->{$oid},
            extra_instance => 'controller');
    }
    foreach my $oid (keys %{$self->{results}->{$oid_arrayVimmEntry_temp}}) {
        temperature($self, oid => $oid, oid_short => $oid_arrayVimmEntry_temp, value => $self->{results}->{$oid_arrayVimmEntry_temp}->{$oid});
    }
}

1;
