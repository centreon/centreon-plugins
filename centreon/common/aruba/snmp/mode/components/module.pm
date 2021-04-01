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

package centreon::common::aruba::snmp::mode::components::module;

use strict;
use warnings;

my %map_card_type = (
    1 => 'lc1',
	2 => 'lc2',
    3 => 'sc1',
    4 => 'sc2',
    5 => 'sw2400',
    6 => 'sw800',
    7 => 'sw200',
    8 => 'm3mk1',
    9 => 'sw3200',
    10 => 'sw3400',
    11 => 'sw3600',
    12 => 'sw650',
    13 => 'sw651',
    14 => 'reserved1',
    15 => 'reserved2',
    16 => 'sw620',
    17 => 'sw3500'
);
my %map_module_status = (
    1 => 'active', 
    2 => 'inactive', 
);

my $mapping = {
    sysExtCardType => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.16.1.2', map => \%map_card_type },
    sysExtCardStatus => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.16.1.12', map => \%map_module_status },
};
my $oid_wlsxSysExtCardEntry = '.1.3.6.1.4.1.14823.2.2.1.2.1.16.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_wlsxSysExtCardEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking modules");
    $self->{components}->{module} = {name => 'modules', total => 0, skip => 0};
    return if ($self->check_filter(section => 'module'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_wlsxSysExtCardEntry}})) {
        next if ($oid !~ /^$mapping->{sysExtCardStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping,
            results => $self->{results}->{$oid_wlsxSysExtCardEntry},
            instance => $instance
        );

        next if ($self->check_filter(section => 'module', instance => $instance));
        $self->{components}->{module}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("Module '%s/%s' status is %s [instance: %s].",
                $result->{sysExtCardType}, $instance, $result->{sysExtCardStatus},
                $instance
        ));
        my $exit = $self->get_severity(section => 'module', value => $result->{sysExtCardStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf("Module '%s/%s' status is %s",
                    $result->{sysExtCardType},
                    $instance,
                    $result->{sysExtCardStatus})
                );
        }
    }
}

1;