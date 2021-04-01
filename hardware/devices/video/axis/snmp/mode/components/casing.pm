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

package hardware::devices::video::axis::snmp::mode::components::casing;

use strict;
use warnings;

my %map_casing_status = (
    1 => 'closed',
    2 => 'open',
);

my $mapping = {
    axiscasingState => { oid => '.1.3.6.1.4.1.368.4.1.6.1.3', map => \%map_casing_status },
    axiscasingName => { oid => '.1.3.6.1.4.1.368.4.1.6.1.2' },
};

my $oid_axiscasingEntry = '.1.3.6.1.4.1.368.4.1.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_axiscasingEntry, start => $mapping->{axiscasingState}->{oid}, end => $mapping->{axiscasingName}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking casings");
    $self->{components}->{casing} = {name => 'casings', total => 0, skip => 0};
    return if ($self->check_filter(section => 'casing'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_axiscasingEntry}})) {
        next if ($oid !~ /^$mapping->{axiscasingState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_axiscasingEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'casing', instance => $instance));
        $self->{components}->{casing}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("casing '%s' status is %s [casing: %s]",
                                    $instance, $result->{axiscasingState}, $result->{axiscasingName}, 
                                    ));
        my $exit = $self->get_severity(section => 'casing', value => $result->{axiscasingState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("casing state is %s [casing: %s]", 
                                                             $result->{axiscasingState}, $result->{axiscasingName}));
        }
     }
}

1;
