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

package storage::hitachi::standard::snmp::mode::components::dku;

use strict;
use warnings;

my %map_status = (
    1 => 'noError',
    2 => 'acute',
    3 => 'serious',
    4 => 'moderate',
    5 => 'service',
);

my $mapping = {
    dkuHWPS             => { oid => '.1.3.6.1.4.1.116.5.11.4.1.1.7.1.2', map => \%map_status, type => 'psu' },
    dkuHWFan            => { oid => '.1.3.6.1.4.1.116.5.11.4.1.1.7.1.3', map => \%map_status, type => 'fan' },
    dkuHWEnvironment    => { oid => '.1.3.6.1.4.1.116.5.11.4.1.1.7.1.4', map => \%map_status, type => 'environment' },
    dkuHWDrive          => { oid => '.1.3.6.1.4.1.116.5.11.4.1.1.7.1.5', map => \%map_status, type => 'drive' },
};
my $oid_raidExMibDKUHWEntry = '.1.3.6.1.4.1.116.5.11.4.1.1.7.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_raidExMibDKUHWEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking drive chassis");
    $self->{components}->{dku} = {name => 'dku', total => 0, skip => 0};
    return if ($self->check_filter(section => 'dku'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raidExMibDKUHWEntry}})) {
        next if ($oid !~ /^$mapping->{dkuHWEnvironment}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_raidExMibDKUHWEntry}, instance => $instance);

        $self->{components}->{dku}->{total}++;

        foreach (keys %{$mapping}) {
            next if ($self->check_filter(section => 'dku', instance => $1 . '.' . $mapping->{$_}->{type}));
            $self->{output}->output_add(long_msg => sprintf("dku '%s' %s status is '%s' [instance: %s].",
                                        $instance, $mapping->{$_}->{type}, $result->{$_},
                                        $instance . '.' . $mapping->{$_}->{type}
                                        ));
            my $exit = $self->get_severity(label => 'dk', section => 'dku', instance => $1 . '.' . $mapping->{$_}->{type}, value => $result->{$_});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity =>  $exit,
                                            short_msg => sprintf("DKU '%s' %s status is '%s'",
                                                                 $instance, $mapping->{$_}->{type}, $result->{$_}));
            }
        }
    }
}

1;