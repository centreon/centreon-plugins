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

package hardware::server::huawei::ibmc::snmp::mode::components::component;

use strict;
use warnings;

my %map_status = (
    1 => 'ok',
    2 => 'minor',
    3 => 'major',
    4 => 'critical',
    5 => 'absence',
    6 => 'unknown',
);

my %map_type = (
    1 => 'baseBoard',
    2 => 'mezzCard',
    3 => 'amcController',
    4 => 'mmcController',
    5 => 'hddBackPlane',
    6 => 'raidCard',
);

my $mapping = {
    componentName               => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.10.50.1.1' },
    componentType               => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.10.50.1.2', map => \%map_type },
    componentStatus             => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.10.50.1.5', map => \%map_status },
};
my $oid_componentDescriptionEntry = '.1.3.6.1.4.1.2011.2.235.1.1.10.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_componentDescriptionEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking component");
    $self->{components}->{component} = {name => 'components', total => 0, skip => 0};
    return if ($self->check_filter(section => 'component'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_componentDescriptionEntry}})) {
        next if ($oid !~ /^$mapping->{componentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_componentDescriptionEntry}, instance => $instance);

        next if ($self->check_filter(section => 'component', instance => $instance));
        next if ($result->{componentStatus} =~ /absence/);
        $self->{components}->{component}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Component '%s' of type '%s' status is '%s' [instance = %s]",
                                    $result->{componentName}, $result->{componentType}, $result->{componentStatus}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'component', value => $result->{componentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Component '%s' of type '%s' status is '%s'",
                                            $result->{componentName}, $result->{componentType}, $result->{componentStatus}));
        }
    }
}

1;