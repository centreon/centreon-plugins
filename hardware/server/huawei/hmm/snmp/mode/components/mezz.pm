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

package hardware::server::huawei::hmm::snmp::mode::components::mezz;

use strict;
use warnings;

my %map_status = (
    1 => 'normal',
    2 => 'minor',
    3 => 'major',
    4 => 'critical',
);

my %map_installation_status = (
    0 => 'absence',
    1 => 'presence',
    2 => 'poweroff',
);

my $mapping = {
    bladeMezzMark            => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2008.1.2' },
    bladeMezzPresent         => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2008.1.4', map => \%map_installation_status },
    bladeMezzHealth          => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2008.1.5', map => \%map_status },
};
my $oid_bladeMezzTable = '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2008.1';

sub load {
    my ($self) = @_;

    $oid_bladeMezzTable =~ s/#/$self->{blade_id}/;
    push @{$self->{request}}, { oid => $oid_bladeMezzTable };
}

sub check {
    my ($self) = @_;

    foreach my $entry (keys $mapping) {
        $mapping->{$entry}->{oid} =~ s/#/$self->{blade_id}/;
    }

    $self->{output}->output_add(long_msg => "Checking mezz cards");
    $self->{components}->{mezz} = {name => 'mezz cards', total => 0, skip => 0};
    return if ($self->check_filter(section => 'mezz'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_bladeMezzTable}})) {
        next if ($oid !~ /^$mapping->{bladeMezzHealth}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_bladeMezzTable}, instance => $instance);

        next if ($self->check_filter(section => 'mezz', instance => $instance));
        next if ($result->{bladeMezzPresent} !~ /presence/);
        $self->{components}->{mezz}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Mezz card '%s' status is '%s' [instance = %s]",
                                    $result->{bladeMezzMark}, $result->{bladeMezzHealth}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'mezz', value => $result->{bladeMezzHealth});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Mezz card '%s' status is '%s'", $result->{bladeMezzMark}, $result->{bladeMezzHealth}));
        }
    }
}

1;