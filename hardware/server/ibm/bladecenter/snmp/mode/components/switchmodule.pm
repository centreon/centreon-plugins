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

package hardware::server::ibm::bladecenter::snmp::mode::components::switchmodule;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown', 
    1 => 'good', 
    2 => 'warning', 
    3 => 'bad',
);

# In MIB 'mmblade.mib' and 'cme.mib'
my $mapping = {
    smHealthState => { oid => '.1.3.6.1.4.1.2.3.51.2.22.3.1.1.1.15', map => \%map_state },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{smHealthState}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking switch module");
    $self->{components}->{switchmodule} = {name => 'switch modules', total => 0, skip => 0};
    return if ($self->check_filter(section => 'switchmodule'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{smHealthState}->{oid}}})) {
        $oid =~ /^$mapping->{smHealthState}->{oid}\.(.*)/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{smHealthState}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'switchmodule', instance => $instance));
        $self->{components}->{switchmodule}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Switch module '%s' status is %s [instance: %s]", 
                                    $instance, $result->{smHealthState},
                                    $instance));
        my $exit = $self->get_severity(section => 'switchmodule', value => $result->{smHealthState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Switch module '%s' status is %s", 
                                            $instance, $result->{smHealthState}));
        }
    }
}

1;