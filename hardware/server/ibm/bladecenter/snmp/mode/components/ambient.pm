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

package hardware::server::ibm::bladecenter::snmp::mode::components::ambient;

use strict;
use warnings;


my $oid_temperature = '.1.3.6.1.4.1.2.3.51.2.2.1';
my $oid_end = '.1.3.6.1.4.1.2.3.51.2.2.1.5';
my $oid_rearLEDCardTempMax = '.1.3.6.1.4.1.2.3.51.2.2.1.5.3.0';
# In MIB 'mmblade.mib' and 'cme.mib'
my $oids = {
    bladecenter => {
        mm          => '.1.3.6.1.4.1.2.3.51.2.2.1.1.2.0',
        frontpanel  => '.1.3.6.1.4.1.2.3.51.2.2.1.5.1.0',
        frontpanel2 => '.1.3.6.1.4.1.2.3.51.2.2.1.5.2.0',
    },
    pureflex => {
        ambient     => '.1.3.6.1.4.1.2.3.51.2.2.1.5.1.0', # rearLEDCardTempAvg
    }
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_temperature, end => $oid_end };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ambient");
    $self->{components}->{ambient} = {name => 'ambient', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ambient'));

    my @sensors = ('mm', 'frontpanel', 'frontpanel2');
    my $label = 'bladecenter';
    if (defined($self->{results}->{$oid_temperature}->{$oid_rearLEDCardTempMax})) {
        @sensors = ('ambient');
        $label = 'pureflex';
    }
    
    foreach my $temp (@sensors) {
        if (!defined($self->{results}->{$oid_temperature}->{$oids->{$label}->{$temp}}) || 
            $self->{results}->{$oid_temperature}->{$oids->{$label}->{$temp}} !~ /([0-9\.]+)/) {
            $self->{output}->output_add(long_msg => sprintf("skip ambient '%s': no values", 
                                                             $temp));
            next;
        }
        
        my $value = $1;
        next if ($self->check_filter(section => 'ambient', instance => $temp));
        $self->{components}->{ambient}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("ambient '%s' is %s degree centigrade.", 
                                                        $temp, $value));
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'ambient', instance => $temp, value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("ambient '%s' is %s degree centigrade", 
                                                        $temp, $value));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C',
            nlabel => 'hardware.ambient.temperature.celsius',
            instances => $temp,
            value => $value,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
