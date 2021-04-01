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

package storage::dell::fluidfs::snmp::mode::components::ad;

use strict;
use warnings;

my $mapping = {
    fluidFSActiveDirectoryStatusConfigured  => { oid => '.1.3.6.1.4.1.674.11000.2000.200.1.1.1' },
    fluidFSActiveDirectoryStatusStatus      => { oid => '.1.3.6.1.4.1.674.11000.2000.200.1.1.2' },
};
my $oid_fluidFSActiveDirectoryStatus = '.1.3.6.1.4.1.674.11000.2000.200.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fluidFSActiveDirectoryStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking active directory");
    $self->{components}->{ad} = {name => 'ad', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ad'));

    my $result = {};
    my $instance = '0';
    if (defined($self->{results}->{$oid_fluidFSActiveDirectoryStatus}->{$mapping->{fluidFSActiveDirectoryStatusConfigured}->{oid}})) {
        $result->{fluidFSActiveDirectoryStatusConfigured} = $self->{results}->{$oid_fluidFSActiveDirectoryStatus}->{$mapping->{fluidFSActiveDirectoryStatusConfigured}->{oid}};
        $result->{fluidFSActiveDirectoryStatusStatus} = $self->{results}->{$oid_fluidFSActiveDirectoryStatus}->{$mapping->{fluidFSActiveDirectoryStatusStatus}->{oid}};        
    } else {
        $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fluidFSActiveDirectoryStatus}, instance => $instance);
    }
    if (!defined($result->{fluidFSActiveDirectoryStatusConfigured}) || $result->{fluidFSActiveDirectoryStatusConfigured} !~ /Yes/i) {
        $self->{output}->output_add(long_msg => "skipping: active directory not configured."); 
        return ;
    }

    return if ($self->check_filter(section => 'ad', instance => $instance));
    $self->{components}->{ad}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("active directory status is '%s' [instance: %s].",
                                                    $result->{fluidFSActiveDirectoryStatusStatus}, $instance
                                ));
    my $exit = $self->get_severity(section => 'ad', value => $result->{fluidFSActiveDirectoryStatusStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity =>  $exit,
                                    short_msg => sprintf("Active directory status is '%s'",
                                                         $result->{fluidFSActiveDirectoryStatusStatus}));
    }
}

1;