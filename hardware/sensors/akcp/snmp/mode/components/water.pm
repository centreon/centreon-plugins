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

package hardware::sensors::akcp::snmp::mode::components::water;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default1_status %map_online);

my $mapping = {
    waterDescription    => { oid => '.1.3.6.1.4.1.3854.3.5.9.1.2' },
    waterStatus         => { oid => '.1.3.6.1.4.1.3854.3.5.9.1.6', map => \%map_default1_status },
    waterGoOffline      => { oid => '.1.3.6.1.4.1.3854.3.5.9.1.8', map => \%map_online },
};
my $oid_waterEntry = '.1.3.6.1.4.1.3854.3.5.9.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_waterEntry, end => $mapping->{waterGoOffline}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking waters");
    $self->{components}->{water} = {name => 'waters', total => 0, skip => 0};
    return if ($self->check_filter(section => 'water'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_waterEntry}})) {
        next if ($oid !~ /^$mapping->{waterGoOffline}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_waterEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'water', instance => $instance));
        if ($result->{waterGoOffline} eq 'offline') {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s': is offline", $result->{waterDescription}));
            next;
        }
        $self->{components}->{water}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("water '%s' status is '%s' [instance = %s]",
                                    $result->{waterDescription}, $result->{waterStatus}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default1', section => 'water', value => $result->{waterStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Water '%s' status is '%s'", $result->{waterDescription}, $result->{waterStatus}));
        }
    }
}

1;
