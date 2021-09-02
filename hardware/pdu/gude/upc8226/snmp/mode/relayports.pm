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

package hardware::pdu::gude::upc8226::snmp::mode::relayports;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => '0' },
        { name => 'relayports', type => 1, cb_prefix_output => 'prefix_relayports_output', message_multiple => 'All relayports are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active-relayports', nlabel => 'pdu.relayports.active', set => {
                key_values => [ { name => 'active_relayports' } ],
                output_template => '%s Active relayport(s)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{relayports} = [
        { label => 'channel-status', type => 2, critical_default => '%{channel_status} !~ /valid/i', set => {
                key_values => [ { name => 'channel_status' }, { name => 'display' } ],
                output_template => 'Status : %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        { label => 'ovp-status', type => 2, critical_default => '%{ovp_status} !~ /ok/i', set => {
                key_values => [ { name => 'ovp_status' }, { name => 'display' } ],
                output_template => 'OVP status : %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        { label => 'current', nlabel => 'pdu.channel.current.ampere', set => {
                key_values => [ { name => 'current', no_value => 0 }, { name => 'display' } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'energy', nlabel => 'pdu.channel.energy.active.kwh', set => {
                key_values => [ { name => 'abs_energy_active', no_value => 0 }, { name => 'display' } ],
                output_template => 'Absolute Energy Active : %.2f kWh',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'kWh', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'frequency', nlabel => 'pdu.channel.frequency.hertz', set => {
                key_values => [ { name => 'frequency', no_value => 0 }, { name => 'display' } ],
                output_template => 'Frequency : %.2f Hz',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'Hz', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'phase-angle', nlabel => 'pdu.channel.pase.angle.degree', set => {
                key_values => [ { name => 'phase_angle', no_value => 0 }, { name => 'display' } ],
                output_template => 'Phase angle : %.2f°',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'deg', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'power-active', nlabel => 'pdu.channel.power.active.watt', set => {
                key_values => [ { name => 'power_active', no_value => 0 }, { name => 'display' } ],
                output_template => 'Active power : %.2f W',
                perfdatas => [
                    { template => '%.2f', unit => 'W', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'power-apparent', nlabel => 'pdu.channel.power.reactive.voltampere', set => {
                key_values => [ { name => 'power_apparent', no_value => 0 }, { name => 'display' } ],
                output_template => 'Apparent power : %.2f VA',
                perfdatas => [
                    { template => '%.2f', unit => 'VA', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'power-factor', nlabel => 'pdu.channel.power.factor', set => {
                key_values => [ { name => 'power_factor', no_value => 0 }, { name => 'display' } ],
                output_template => 'Power factor : %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'power-reactive', nlabel => 'pdu.channel.power.reactive.var', set => {
                key_values => [ { name => 'power_reactive', no_value => 0 }, { name => 'display' } ],
                output_template => 'Reactive power : %.2f Var',
                perfdatas => [
                    { template => '%.2f', unit => 'Var', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'voltage', nlabel => 'pdu.channel.voltage.volt', set => {
                key_values => [ { name => 'voltage', no_value => 0 }, { name => 'display' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'V', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_relayports_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-channel:s' => { name => 'filter_channel' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $epc8226portNumber = '.1.3.6.1.4.1.28507.58.1.3.1.1.0';
    my $epc8226portEntry = '.1.3.6.1.4.1.28507.58.1.3.1.2.1';
    my $epc8226spPowerEntry = '.1.3.6.1.4.1.28507.58.1.5.5.2.1';

    my $port_status_mapping = {
        0 => 'off',
        1 => 'on'
    };
    my $sp_status_mapping = {
        0 => 'not active',
        1 => 'valid'
    };
    

    my $ports_mapping = {
        epc8226PortName  => { oid => '.1.3.6.1.4.1.28507.58.1.3.1.2.1.2', label => 'port_name' },
        epc8226PortState => { oid => '.1.3.6.1.4.1.28507.58.1.3.1.2.1.3', label => 'port_status', map => $port_status_mapping }
    };

    my $singleport_mapping = {
        epc8226spChanStatus      => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.2', label => 'sp_status', map => $sp_status_mapping },
        epc8226spAbsEnergyActive => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.3', label => 'abs_energy_active' },
        epc8226spPowerActive     => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.4', label => 'active_power' },
        epc8226spCurrent         => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.5', label => 'current' },
        epc8226spVoltage         => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.6', label => 'voltage' },
        epc8226spFrequency       => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.7', label => 'frequency' },
        epc8226spPowerFactor     => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.8', label => 'power_factor' },
        epc8226spPangle          => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.9', label => 'phase_angle' },
        epc8226spPowerApparent   => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.10', label => 'power_apparent' },
        epc8226spPowerReactive   => { oid => '.1.3.6.1.4.1.28507.58.1.5.5.2.1.11', label => 'power_reactive' }
    };

    my $global_results = $options{snmp}->get_leef( oids => [ $epc8226portNumber ], nothing_quit => 1);
    my $relayports_results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $epc8226portEntry, start => $ports_mapping->{epc8226PortName}->{oid}, end => $ports_mapping->{epc8226PortState}->{oid} },
            { oid => $epc8226spPowerEntry, start => $singleport_mapping->{epc8226spChanStatus}->{oid}, end => $singleport_mapping->{epc8226spPowerReactive}->{oid} }
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        active_relayports => $global_results->{$epc8226portNumber}
    };

    my $ports_result;
    foreach my $port_oid (keys %{$relayports_results->{$epc8226portEntry}}) {
        next if ($port_oid !~ /^$ports_mapping->{epc8226PortName}->{oid}\.(.*)$/);
        my $instance = $1;
        $ports_result->{$instance} = $options{snmp}->map_instance(mapping => $ports_mapping, results => $relayports_results->{$epc8226portEntry}, instance => $instance);
    };
    my $sp_result;
    foreach my $singleport_oid (keys %{$relayports_results->{$epc8226spPowerEntry}}) {
        next if ($singleport_oid !~ /^$singleport_mapping->{epc8226spChanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        $sp_result->{$instance} = $options{snmp}->map_instance(mapping => $singleport_mapping, results => $relayports_results->{$epc8226spPowerEntry}, instance => $instance);
    };
    use Data::Dumper; print Dumper($sp_result); exit 0;

    # foreach my $singleport_id (keys %{$ports_result}) {
    #     #next if (defined($self->{option_results}->{filter_singleport}) && $self->{option_results}->{filter_port} !~ /$singleport_id/);
    #     foreach my $stat (keys %{$ports_result->{$singleport_id}}) {
    #         # if ($stat =~ m/epc8226Current|epc8226AbsEnergyActive|epc8226PowerFactor/ && defined($ports_result->{$singleport_id}->{$stat})) {
    #         #     $ports_result->{$singleport_id}->{$stat} *= 0.001;
    #         # }
    #         # if ($stat =~ m/epc8226Frequency|epc8226AbsEnergyActive/ && defined($ports_result->{$singleport_id}->{$stat})) {
    #         #     $ports_result->{$singleport_id}->{$stat} *= 0.01;
    #         # }
    #         $self->{relayports}->{$singleport_id}->{display} = $ports_result->{$singleport_id}->{};
    #         $self->{relayports}->{$singleport_id}->{ $singleport_mapping->{$stat}->{label} } = $ports_result->{$singleport_id}->{$stat};
    #     }
    #     # foreach my $stat (keys %{$ovp_result->{$singleport_id}}) {
    #     #     $self->{relayports}->{$singleport_id}->{ $ovp_mapping->{$stat}->{label} } = $ovp_result->{$singleport_id}->{$stat};
    #     # }
    # }
}

1;

__END__

=head1 MODE

Check Gude UPC8226 Power relayports statistics.

=over 8

=item B<--filter-channel>

Filter channel ID (can be a regexp).

=item B<--warning-channel-status>

Warning threshold for channel status (Default: none)

=item B<--critical-channel-status>

Critical threshold for channel status (Default: '%{channel_status} !~ /valid/i')

=item B<--warning-ovp-status>

Warning threshold for OVP (OverVoltage Protection) status (Default: none)

=item B<--critical-ovp-status>

Critical threshold for OVP (OverVoltage Protection) status (Default: '%{ovp_status} !~ /ok/i')

=item B<--warning-*>

Threshold warning.
Can be: 'active-relayports', 'channel-status', 'ovp-status', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=item B<--critical-*>

Can be: 'active-relayports', 'channel-status', 'ovp-status', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=back

=cut
