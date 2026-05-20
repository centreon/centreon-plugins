#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::aviat::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|voltage|power)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{components_path} = 'network::aviat::snmp::mode::components';
    $self->{components_module} = ['power', 'temperature', 'voltage'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    my $mapping_slot = {
        serial => { oid => '.1.3.6.1.4.1.2509.12.8.31.2.10.1.2' }, # fMfgDetailsInfoSerialNumber
        type   => { oid => '.1.3.6.1.4.1.2509.12.8.31.2.10.1.9' }  # fMfgDetailsInfoUnitType
    };
    my $mapping_perf = {
        name    => { oid => '.1.3.6.1.4.1.2509.12.8.22.2.1.1.2' }, # fPerformParamName
        unit    => { oid => '.1.3.6.1.4.1.2509.12.8.22.2.1.1.3' }, # fPerformParamUnit
        scale   => { oid => '.1.3.6.1.4.1.2509.12.8.22.2.1.1.4' }, # fPerformParamScaleFactor
        reading => { oid => '.1.3.6.1.4.1.2509.12.8.22.2.1.1.5' }  # fPerformParamReading
    };

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [map({ oid => $_->{oid} }, values(%$mapping_slot))],
        return_type => 1,
        nothing_quit => 1
    );
    my $slots = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_slot->{serial}->{oid}\.(\d+)\.(.*)/);
        my ($slot_index, $instance) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping_slot, results => $snmp_result, instance => $slot_index . '.' . $instance);

        next if ($result->{serial} =~ /unknown/i);

        $slots->{$slot_index} = $result->{type} . ' ' . $result->{serial};
    }

    my $oid_fPerformParametersTable = '.1.3.6.1.4.1.2509.12.8.22.2.1';

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_fPerformParametersTable,
        start => $mapping_perf->{name}->{oid},
        end => $mapping_perf->{reading}->{oid},
        nothing_quit => 1
    );
    $self->{perfs} = [];
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_perf->{name}->{oid}\.(\d+)\.(.*)$/);
        my ($slot_index, $instance) = ($1, $2);

        next if (!defined($slots->{$slot_index}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_perf, results => $snmp_result, instance => $slot_index . '.' . $instance);
    
        push @{$self->{perfs}}, {
            instance => $slot_index . '.' . $instance,
            slotName => $slots->{$slot_index},
            %$result
        };
    }

    @{$self->{perfs}} = sort { $a->{instance} cmp $b->{instance} } @{$self->{perfs}};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
         'display-instances' => { name => 'display_instances' }
    });

    return $self;
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'power', 'temperature', 'voltage'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature --filter=contact).
You can also exclude items from specific instances: --filter=temperature,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--warning>

Set warning threshold for 'power', 'temperature', 'voltage' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'power', 'temperature', 'voltage' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
