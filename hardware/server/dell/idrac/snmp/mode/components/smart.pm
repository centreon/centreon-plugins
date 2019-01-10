#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::idrac::snmp::mode::components::smart;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_smart_state);

my $mapping = {
    smartState    => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.31', map => \%map_smart_state },
    physicalDiskFQDD            => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.54' },
};
my $oid_physicalDiskTableEntry = '.1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_physicalDiskTableEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking S.M.A.R.T on physical disks");
    $self->{components}->{smart} = {name => 'physical disks smart alert indication', total => 0, skip => 0};
    return if ($self->check_filter(section => 'smart'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_physicalDiskTableEntry}})) {
        next if ($oid !~ /^$mapping->{smartState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_physicalDiskTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'smart', instance => $instance));
        $self->{components}->{smart}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Physical disk '%s' S.M.A.R.T state is '%s' [instance = %s]",
                                    $result->{physicalDiskFQDD}, $result->{smartState}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(section => 'smart.state', value => $result->{smartState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Physical disk '%s' S.M.A.R.T state is '%s'", $result->{physicalDiskFQDD}, $result->{smartState}));
            next;
        }
    }
}

1;
