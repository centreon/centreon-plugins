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

package storage::dell::compellent::snmp::mode::components::server;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scServerStatus    => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.27.1.3', map => \%map_sc_status },
    scServerName      => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.27.1.4' },
};
my $oid_scServerEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.27.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scServerEntry, begin => $mapping->{scServerStatus}->{oid}, end => $mapping->{scServerName}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking servers");
    $self->{components}->{server} = {name => 'servers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'server'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scServerEntry}})) {
        next if ($oid !~ /^$mapping->{scServerStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scServerEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'server', instance => $instance));
        $self->{components}->{server}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("server '%s' status is '%s' [instance = %s]",
                                    $result->{scServerName}, $result->{scServerStatus}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default', section => 'server', value => $result->{scServerStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Server '%s' status is '%s'", $result->{scServerName}, $result->{scServerStatus}));
        }
    }
}

1;