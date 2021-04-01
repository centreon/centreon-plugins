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

package storage::quantum::scalar::snmp::mode::components::subsystem;

use strict;
use warnings;
use storage::quantum::scalar::snmp::mode::components::resources qw($map_rassubsytem_status);

# In MIB 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'
my $mapping = {
    libraryStatus => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.50.1', label => 'library', instance => 1 },
    driveStatus => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.50.2', label => 'drive', instance => 2 },
    mediaStatus => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.50.3', label => 'media', instance => 3 },
};
my $oid_rasSubSystem = '.1.3.6.1.4.1.3697.1.10.15.5.50';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rasSubSystem };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking subsystems");
    $self->{components}->{subsystem} = {name => 'subsystems', total => 0, skip => 0};
    return if ($self->check_filter(section => 'subsystem'));

    return if (!defined($self->{results}->{$oid_rasSubSystem}) ||
        scalar(keys %{$self->{results}->{$oid_rasSubSystem}}) <= 0);

    foreach (values %$mapping) {
        my $status = defined($self->{results}->{$oid_rasSubSystem}->{$_->{oid} . '.0'}) ?
            $map_rassubsytem_status->{ $self->{results}->{$oid_rasSubSystem}->{$_->{oid} . '.0'} } : 
            $map_rassubsytem_status->{ $self->{results}->{$oid_rasSubSystem}->{$_->{oid}} };
        next if (!defined($status));

        next if ($self->check_filter(section => 'subsystem', instance => $_->{instance}));
        $self->{components}->{subsystem}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "subsystem '%s' status is %s [instance: %s].",
                $_->{label}, $status,
                $_->{instance}
            )
        );
        my $exit = $self->get_severity(section => 'subsystem', label => 'default', instance => $_->{instance}, value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf("subsystem '%s' status is %s", $_->{label}, $status)
            );
        }
    }
}

1;
