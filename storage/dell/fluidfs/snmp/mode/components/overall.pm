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

package storage::dell::fluidfs::snmp::mode::components::overall;

use strict;
use warnings;

my $mapping = {
    fluidFSNASApplianceApplianceServiceTag  => { oid => '.1.3.6.1.4.1.674.11000.2000.200.1.16.1.3' },
    fluidFSNASApplianceStatus               => { oid => '.1.3.6.1.4.1.674.11000.2000.200.1.16.1.5' },
    fluidFSNASApplianceModel                => { oid => '.1.3.6.1.4.1.674.11000.2000.200.1.16.1.6' },
};
my $oid_fluidFSNASApplianceEntry = '.1.3.6.1.4.1.674.11000.2000.200.1.16.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fluidFSNASApplianceEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking nas overall");
    $self->{components}->{overall} = {name => 'overall', total => 0, skip => 0};
    return if ($self->check_filter(section => 'overall'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fluidFSNASApplianceEntry}})) {
        next if ($oid !~ /^$mapping->{fluidFSNASApplianceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fluidFSNASApplianceEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'overall', instance => $instance));
        $self->{components}->{overall}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("nas '%s/%s' overall status is '%s' [instance = %s]",
                                    $result->{fluidFSNASApplianceApplianceServiceTag}, $result->{fluidFSNASApplianceModel},
                                    $result->{fluidFSNASApplianceStatus}, $instance
                                    ));
        
        my $exit = $self->get_severity(label => 'default', section => 'overall', value => $result->{fluidFSNASApplianceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("nas '%s/%s' overall status is '%s'",
                                            $result->{fluidFSNASApplianceApplianceServiceTag}, $result->{fluidFSNASApplianceModel},
                                            $result->{fluidFSNASApplianceStatus}
                                       ));
        }
    }
}

1;