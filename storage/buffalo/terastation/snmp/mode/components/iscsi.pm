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

package storage::buffalo::terastation::snmp::::mode::components::iscsi;

use strict;
use warnings;

my %map_iscsi_status = (
    1 => 'unknown', 1 => 'connected', 2 => 'standing-by',
);

my $mapping = {
    nasISCSIName    => { oid => '.1.3.6.1.4.1.5227.27.1.9.1.2' },
    nasISCSIStatus  => { oid => '.1.3.6.1.4.1.5227.27.1.9.1.3', map => \%map_iscsi_status },
};
my $nasISCSIEntry = '.1.3.6.1.4.1.5227.27.1.9.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $nasISCSIEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking iscsi");
    $self->{components}->{iscsi} = { name => 'iscsi', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'iscsi'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $nasISCSIEntry }})) {
        next if ($oid !~ /^$mapping->{nasISCSIStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $nasISCSIEntry }, instance => $instance);

        next if ($self->check_filter(section => 'iscsi', instance => $instance, name => $result->{nasISCSIName}));
        $self->{components}->{iscsi}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("iscsi '%s' status is '%s' [instance: %s].",
                                    $result->{nasISCSIName}, $result->{nasISCSIStatus}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'iscsi', value => $result->{nasISCSIStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Iscsi '%s' status is '%s'",
                                                             $result->{nasISCSIName}, $result->{nasISCSIStatus}));
        }
    }
}

1;
