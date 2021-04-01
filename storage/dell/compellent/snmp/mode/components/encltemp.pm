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

package storage::dell::compellent::snmp::mode::components::encltemp;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scEnclTempStatus    => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.23.1.3', map => \%map_sc_status },
    scEnclTempLocation  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.23.1.4' },
    scEnclTempCurrentC  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.23.1.5' },
};
my $oid_scEnclTempEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.23.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scEnclTempEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking enclosure temperatures");
    $self->{components}->{encltemp} = {name => 'enclosure temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'encltemp'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scEnclTempEntry}})) {
        next if ($oid !~ /^$mapping->{scEnclTempStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scEnclTempEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'encltemp', instance => $instance));

        $self->{components}->{encltemp}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("enclosure temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{scEnclTempLocation}, $result->{scEnclTempStatus}, $instance, 
                                    defined($result->{scEnclTempCurrentC}) ? $result->{scEnclTempCurrentC} : '-'));
        
        my $exit = $self->get_severity(label => 'default', section => 'encltemp', value => $result->{scEnclTempStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Enclosure temperature '%s' status is '%s'", $result->{scEnclTempLocation}, $result->{scEnclTempStatus}));
        }
        
        next if (!defined($result->{scEnclTempCurrentC}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'encltemp', instance => $instance, value => $result->{scEnclTempCurrentC});
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Enclosure temperature '%s' is %s C", $result->{scEnclTempLocation}, $result->{scEnclTempCurrentC}));
        }
        $self->{output}->perfdata_add(
            label => 'encltemp', unit => 'C',
            nlabel => 'hardware.enclosure.temperature.celsius',
            instances => $instance,
            value => $result->{scEnclTempCurrentC},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
