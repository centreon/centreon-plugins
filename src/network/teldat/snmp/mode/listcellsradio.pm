#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::teldat::snmp::mode::listcellsradio;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping = {
    imei   => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.5' }, # teldatCellularInfoInterfaceModuleIMEI : Cellular module IMEI.
    imsi   => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.6' }, # teldatCellularInfoInterfaceModuleIMSI : Cellular module IMSI.
    simIcc => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.8' } # teldatCellularInfoInterfaceSIMIcc : Cellular active SIM ICC.
};
my $oid_teldatCellularInfoInterfaceEntry = '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1'; # teldatInfoInterfaceTable

my $interface_types = {
    1 => 'control vocal',
    2 => 'data primary',
    3 => 'data auxiliary'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_teldatCellularInfoInterfaceEntry,
        start => $mapping->{imei}->{oid},
        end => $mapping->{simIcc}->{oid},
        nothing_quit => 1
    );

    my $results = {};
    my $modules = {};
    my $module_num = 0;
    my $interface_type = 0;
    foreach my $oid ($options{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{imei}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        next if ($result->{imei} !~ /^[0-9]+$/);

        if (!defined($modules->{$module_num}) || $result->{imei} ne $modules->{$module_num}) {
            $module_num++;
            $interface_type = 0;
            $modules->{$module_num} = $result->{imei};
        }
        if (defined($modules->{$module_num})) {
            $interface_type++;
        }

        my $module = 'module' . $module_num;

        $results->{$instance} = {
            module => $module,
            moduleNum => $module_num,
            interfaceType => $interface_types->{$interface_type},
            imei => $result->{imei},
            imsi => $result->{imsi},
            simIcc => $result->{simIcc}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $name (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            '[module = ' . $results->{$name}->{module} . ']' .
            '[moduleNum = ' . $results->{$name}->{moduleNum} . ']' .
            '[interfaceType = ' . $results->{$name}->{interfaceType} . ']' .
            join('', map("[$_ = " . $results->{$name}->{$_} . ']', keys(%$mapping)))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List cellular radio interfaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['module', 'moduleNum', 'interfaceType', keys %$mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {        
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List cellular radio interfaces.

=over 8

=back

=cut
