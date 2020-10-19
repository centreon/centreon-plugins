#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package hardware::pdu::cyberpower::snmp::mode::outlets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf(
        "state: '%s' %s",
        $self->{result_values}->{state},
        '[phase: ' . $self->{result_values}->{phase} . ']',
    );
}

sub device_long_output {
    my ($self, %options) = @_;

    return "checking device '" . $options{instance_value}->{display} . "'";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub prefix_outlet_output {
    my ($self, %options) = @_;

    return "outlet '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'outlets', display_long => 1, cb_prefix_output => 'prefix_outlet_output',  message_multiple => 'outlets are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{outlets} = [
        { label => 'status', type => 2, critical_default => '%{state} =~ /off/i', set => {
                key_values => [ { name => 'state' }, { name => 'bank' }, { name => 'phase' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current', nlabel => 'outlet.current.ampere', set => {
                key_values => [ { name => 'current', no_value => 0 }, { name => 'display' } ],
                output_template => 'current : %s A',
                perfdatas => [
                    { template => '%s', unit => 'A', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

my $map_pdu_status = {
    1 => 'on', 2 => 'off'
};
my $map_pdu_phase = {
    1 => 'phase1', 2 => 'phase2', 3 => 'phase3',
    4 => 'phase1-2', 5 => 'phase2-3', 6 => 'phase3-1'
};

sub check_pdu {
    my ($self, %options) = @_;

    return if (scalar(keys %{$self->{devices}}) > 0);

    $self->{devices}->{ $options{device} } = {
        display => $options{device},
        outlets => {}
    };

    my $mapping = {
        name    => { oid => '.1.3.6.1.4.1.3808.1.1.3.3.5.1.1.2' }, # ePDUOutletStatusOutletName
        phase   => { oid => '.1.3.6.1.4.1.3808.1.1.3.3.5.1.1.3', map => $map_pdu_phase }, # ePDUOutletStatusOutletPhase
        state   => { oid => '.1.3.6.1.4.1.3808.1.1.3.3.5.1.1.4', map => $map_pdu_status }, # ePDUOutletStatusOutletState
        bank    => { oid => '.1.3.6.1.4.1.3808.1.1.3.3.5.1.1.6' }, # ePDUOutletStatusOutletBank
        current => { oid => '.1.3.6.1.4.1.3808.1.1.3.3.5.1.1.7' }  # ePDUOutletStatusLoad
    };

    my $oid_ePDUOutletStatusEntry = '.1.3.6.1.4.1.3808.1.1.3.3.5.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ePDUOutletStatusEntry,
        start => $mapping->{name}->{oid},
        end => $mapping->{current}->{oid}
    );

    my $duplicated = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{state}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        my $name = $result->{name} . ' bank ' . $result->{bank};
        $name = $instance if (defined($duplicated->{$name}));
        if (defined($self->{devices}->{ $options{device} }->{outlets}->{$name})) {
            $duplicated->{$name} = 1;
            my $instance2 = $self->{devices}->{ $options{device} }->{outlets}->{$name}->{instance};
            $self->{devices}->{ $options{device} }->{outlets}->{$instance2} = $self->{devices}->{ $options{device} }->{outlets}->{$name};
            $self->{devices}->{ $options{device} }->{outlets}->{$instance2}->{display} = $instance2;
            delete $self->{devices}->{ $options{device} }->{outlets}->{$name};
            $name = $instance;
        }

        $result->{current} /= 10;
        $self->{devices}->{ $options{device} }->{outlets}->{$name} = {
            instance => $instance,
            display => $name,
            %$result
        };
    }
}

my $map_pdu2_status = {
    1 => 'on',
    2 => 'off',
};
my $map_pdu2_phase = {
    1 => 'seqPhase1ToNeutral', 2 => 'seqPhase2ToNeutral',
    3 => 'seqPhase3ToNeutral', 4 => 'seqPhase1ToPhase2',
    5 => 'seqPhase2ToPhase3',  6 => 'seqPhase3ToPhase1',
};
my $oid_ePDUIdentName = '.1.3.6.1.4.1.3808.1.1.3.1.1';
my $oid_ePDU2DeviceConfigName = '.1.3.6.1.4.1.3808.1.1.6.3.2.1.3';

sub check_pdu2 {
    my ($self, %options) = @_;

    my $mapping_switched = {
        bank   => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.1.3.1.6' }, # ePDU2OutletSwitchedInfoBank
        module => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.1.4.1.2' }, # ePDU2OutletSwitchedStatusModuleIndex
        number => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.1.4.1.3' }, # ePDU2OutletSwitchedStatusNumber
        name   => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.1.4.1.4' }, # ePDU2OutletSwitchedStatusName
        state  => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.1.4.1.5', map => $map_pdu2_status } # ePDU2OutletSwitchedStatusState,
    };

    my $mapping_metered = {
        module  => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.2.3.1.2' }, # ePDU2OutletMeteredInfoModuleIndex
        number  => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.2.3.1.3' }, # ePDU2OutletMeteredInfoNumber
        name    => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.2.3.1.4' }, # ePDU2OutletMeteredInfoName
        phase   => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.2.3.1.5', map => $map_pdu2_phase }, # ePDU2OutletMeteredInfoLayout
        bank    => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.2.3.1.7' }, # ePDU2OutletMeteredInfoBank
        current => { oid => '.1.3.6.1.4.1.3808.1.1.6.6.2.4.1.6' }  # ePDU2OutletMeteredStatusLoad
    };

    my $oid_ePDU2OutletSwitchedStatusEntry = '.1.3.6.1.4.1.3808.1.1.6.6.1.4.1';
    my $snmp_result_switched = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping_switched->{bank}->{oid} },
            { oid => $oid_ePDU2OutletSwitchedStatusEntry, start => $mapping_switched->{module}->{oid}, end => $mapping_switched->{state}->{oid} }
        ],
        return_type => 1,
    );

    my $oid_ePDU2OutletMeteredInfoEntry = '.1.3.6.1.4.1.3808.1.1.6.6.2.3.1';
    my $oid_ePDU2OutletMeteredStatusEntry = '.1.3.6.1.4.1.3808.1.1.6.6.2.4.1';
    my $snmp_result_metered = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_ePDU2OutletMeteredInfoEntry, start => $mapping_metered->{module}->{oid}, end => $mapping_metered->{bank}->{oid} },
            { oid => $oid_ePDU2OutletMeteredStatusEntry, start => $mapping_metered->{current}->{oid}, end => $mapping_metered->{current}->{oid} }
        ],
        return_type => 1,
    );

    my $result_metered = {};
    foreach (keys %$snmp_result_metered) {
        next if (! /^$mapping_metered->{module}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping_metered, results => $snmp_result_metered, instance => $1);
        $result_metered->{ $result->{module} . ':' . $result->{bank} . ':' . $result->{number} } = $result;
    }

    my $duplicated = {};
    foreach (keys %$snmp_result_switched) {
        next if (! /^$mapping_switched->{module}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping_switched, results => $snmp_result_switched, instance => $1);

        my $device_name = $options{devices}->{ $oid_ePDU2DeviceConfigName . '.' . $result->{module} };
        if (!defined($self->{devices}->{$device_name})) {
            $self->{devices}->{$device_name} = {
                display => $device_name,
                outlets => {}
            };
        }

        my $instance = $result->{bank} . ':' . $result->{number};
        my $name = $result->{name} . ' bank ' . $result->{bank};
        $name = $instance if (defined($duplicated->{$name}));
        if (defined($self->{devices}->{$device_name}->{outlets}->{$name})) {
            $duplicated->{$name} = 1;
            my $instance2 = $self->{devices}->{$device_name}->{outlets}->{$name}->{instance};
            $self->{devices}->{$device_name}->{outlets}->{$instance2} = $self->{devices}->{$device_name}->{outlets}->{$name};
            $self->{devices}->{$device_name}->{outlets}->{$instance2}->{display} = $instance2;
            delete $self->{devices}->{$device_name}->{outlets}->{$name};
            $name = $instance;
        }

        $result_metered->{ $result->{module} . ':' . $result->{bank} . ':' . $result->{number} }->{current} /= 10;
        $self->{devices}->{$device_name}->{outlets}->{$name} = {
            instance => $instance,
            display => $name,
            state => $result->{state},
            %{$result_metered->{ $result->{module} . ':' . $result->{bank} . ':' . $result->{number} }}
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_ePDUIdentName },
            { oid => $oid_ePDU2DeviceConfigName }
        ],
        nothing_quit => 1
    );

    $self->{devices} = {};
    $self->check_pdu2(snmp => $options{snmp}, devices => $snmp_result->{$oid_ePDU2DeviceConfigName});
    $self->check_pdu(
        snmp => $options{snmp},
        device => defined($snmp_result->{$oid_ePDUIdentName}->{$oid_ePDUIdentName . '.0'}) ? $snmp_result->{$oid_ePDUIdentName}->{$oid_ePDUIdentName . '.0'} : 'unknown'
    );
}

1;

__END__

=head1 MODE

Check outlets.

=over 8

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %%{state}, %{phase}, %{bank}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{phase}, %{bank}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /off/').
Can used special variables like: %{state}, %{phase}, %{bank}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'current'.

=back

=cut
