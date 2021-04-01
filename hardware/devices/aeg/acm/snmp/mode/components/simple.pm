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

package hardware::devices::aeg::acm::snmp::mode::components::simple;

use strict;
use warnings;

my %map_status_1000 = (0 => 'false', 1 => 'true');
my %map_status_1d = (0 => 'off', 1 => 'on');

my $mapping_acm1000 = {
    label   => { oid => '.1.3.6.1.4.1.15416.37.8.1.1.2' },
    active  => { oid => '.1.3.6.1.4.1.15416.37.8.1.1.3', map => \%map_status_1000 },
};
my $mapping_acmi1000 = {
    label   => { oid => '.1.3.6.1.4.1.15416.38.8.1.1.2' },
    active  => { oid => '.1.3.6.1.4.1.15416.38.8.1.1.3', map => \%map_status_1000 },
};
my $mapping_acm1d = {
    label   => { oid => '.1.3.6.1.4.1.15416.29.8.1.4' },
    active  => { oid => '.1.3.6.1.4.1.15416.29.8.1.3', map => \%map_status_1d },
};

my $oid_simpleAlarmTableEntryAcm1000 = '.1.3.6.1.4.1.15416.37.8.1.1';
my $oid_simpleAlarmTableEntryAcmi1000 = '.1.3.6.1.4.1.15416.38.8.1.1';
my $oid_simpleAlarmTableEntryAcm1d = '.1.3.6.1.4.1.15416.29.8.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_simpleAlarmTableEntryAcm1000 },
                              { oid => $oid_simpleAlarmTableEntryAcmi1000 },
                              { oid => $oid_simpleAlarmTableEntryAcm1d };
}

sub check_alarms {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{label}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        
        next if (centreon::plugins::misc::trim($result->{label}) eq '');
        next if ($self->check_filter(section => 'simple', instance => $instance));
        $self->{components}->{simple}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Simple alarm '%s' status is '%s' [instance = %s]",
                                                        centreon::plugins::misc::trim($result->{label}),
                                                        $result->{active}, $instance));
        
        my $exit = $self->get_severity(section => 'simple', instance => $instance, value => $result->{active});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Simple alarm '%s' status is '%s'", centreon::plugins::misc::trim($result->{label}), $result->{active}));
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking simple alarms");
    $self->{components}->{simple} = {name => 'simple alarms', total => 0, skip => 0};
    return if ($self->check_filter(section => 'simple'));
    
    check_alarms($self, entry => $oid_simpleAlarmTableEntryAcm1000, mapping => $mapping_acm1000);
    check_alarms($self, entry => $oid_simpleAlarmTableEntryAcmi1000, mapping => $mapping_acmi1000);
    check_alarms($self, entry => $oid_simpleAlarmTableEntryAcm1d, mapping => $mapping_acm1d);
}

1;
