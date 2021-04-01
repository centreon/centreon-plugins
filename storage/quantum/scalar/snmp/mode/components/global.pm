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

package storage::quantum::scalar::snmp::mode::components::global;

use strict;
use warnings;
use storage::quantum::scalar::snmp::mode::components::resources qw($map_rassubsytem_status);

# In MIB 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'
my $oid_mrTapeLibrary = '.1.3.6.1.4.1.3697.1.10.15.5';
my $oid_libraryFirmwareVersion = '.1.3.6.1.4.1.3697.1.10.15.5.9';
my $oid_libraryGlobalStatus = '.1.3.6.1.4.1.3697.1.10.15.5.10';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_mrTapeLibrary, start => $oid_libraryFirmwareVersion, end => $oid_libraryGlobalStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking global");
    $self->{components}->{global} = {name => 'global', total => 0, skip => 0};
    return if ($self->check_filter(section => 'global'));

    return if (!defined($self->{results}->{$oid_mrTapeLibrary}) ||
        scalar(keys %{$self->{results}->{$oid_mrTapeLibrary}}) <= 0);

    my $instance = '0';
    my $status = defined($self->{results}->{$oid_mrTapeLibrary}->{$oid_libraryGlobalStatus . '.0'}) ?
        $map_rassubsytem_status->{ $self->{results}->{$oid_mrTapeLibrary}->{$oid_libraryGlobalStatus . '.0'} } : 
        $map_rassubsytem_status->{ $self->{results}->{$oid_mrTapeLibrary}->{$oid_libraryGlobalStatus} };

    return if ($self->check_filter(section => 'global', instance => $instance));
    $self->{components}->{global}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            'library global status is %s [instance: %s]',
            $status, $instance
        )
    );
    my $exit = $self->get_severity(section => 'global', label => 'default', value => $status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity =>  $exit,
            short_msg =>
                sprintf("Library global status is %s", $status
            )
        );
    }
}

1;
