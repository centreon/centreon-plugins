#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package hardware::pdu::schleifenbauer::gateway::snmp::mode::components::contact;

use strict;
use warnings;
use hardware::pdu::schleifenbauer::gateway::snmp::mode::components::resources qw($oid_pdumeasuresEntry $oid_deviceName $mapping);

sub load {}

sub check_contact {
    my ($self, %options) = @_;

    my $description = $options{device_name};
    $description .= '.' . ((defined($options{sensor_name}) && $options{sensor_name} ne '') ? $options{sensor_name} : $options{num});
    
    next if ($self->check_filter(section => 'contact', instance => $options{instance}, name => $description));
    $self->{components}->{contact}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("contact '%s' is %s [instance = %s]",
                                $description, $options{value}, $options{instance}));
         
    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'contact', instance => $options{instance}, name => $description, value => $options{value});
    
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Contact '%s' is %s %%", $description, $options{value}));
    }
    $self->{output}->perfdata_add(
        label => 'contact',
        nlabel => 'hardware.sensor.contact.count',
        instances => [$options{device_name}, (defined($options{sensor_name}) && $options{sensor_name} ne '') ? $options{sensor_name} : $options{num}],
        value => $options{value},
        warning => $warn,
        critical => $crit,
        min => 0, max => 100
    );
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking contact");
    $self->{components}->{contact} = { name => 'contact', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'contact'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_deviceName}})) {
        $oid =~ /^$oid_deviceName.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_pdumeasuresEntry}, instance => $instance);

        for (my $i = 1; $i <= 16; $i++) {
            next if (!defined($result->{'sensor' . $i . 'Type'}) || $result->{'sensor' . $i . 'Type'} !~ /I/);
            check_contact($self, 
                instance => $instance,
                device_name => $self->{results}->{$oid_deviceName}->{$oid},
                num => $i,
                value => $result->{'sensor' . $i . 'Value'},
                sensor_name => $result->{'sensor' . $i . 'Name'},
            );
        }
    }
}

1;
