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

package hardware::pdu::gude::upc8226::snmp::mode::channels;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => '0' },
        { name => 'channels', type => 1, cb_prefix_output => 'prefix_channels_output', message_multiple => 'All channels are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active-channels', nlabel => 'pdu.channels.active', set => {
                key_values => [ { name => 'active_channels' } ],
                output_template => '%s Active power channel(s)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{channels} = [
        { label => 'channel-status', type => 2, critical_default => '%{channel_status} !~ /valid/i', set => {
                key_values => [ { name => 'channel_status' }, { name => 'display' } ],
                output_template => 'Global status : %s',
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
        { label => 'ps-status', type => 2, critical_default => '%{ps_status} !~ /up/i', set => {
                key_values => [ { name => 'ps_status' }, { name => 'display' } ],
                output_template => 'PS status : %s',
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

sub prefix_channels_output {
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

    my $epc8226ActivePowerChan = '.1.3.6.1.4.1.28507.58.1.5.1.1.0';
    my $epc8226PowerEntry = '.1.3.6.1.4.1.28507.58.1.5.1.2.1';
    my $epc8226OVPEntry = '.1.3.6.1.4.1.28507.58.1.5.2.1';
    my $epc8226PwrSupplyEntry = '.1.3.6.1.4.1.28507.58.1.5.13.1';

    my $channel_status_mapping = {
        0 => 'not active',
        1 => 'valid'
    };
    my $ovp_status_mapping = {
        0 => 'failure',
        1 => 'ok',
        2 => 'unknown'
    };
    my $ps_status_mapping = {
        0 => 'down',
        1 => 'up'
    };

    my $power_mapping = {
        epc8226ChanStatus      => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.2', label => 'channel_status', map => $channel_status_mapping },
        epc8226AbsEnergyActive => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.3', label => 'abs_energy_active' },
        epc8226PowerActive     => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.4', label => 'power_active' },
        epc8226Current         => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.5', label => 'current' },
        epc8226Voltage         => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.6', label => 'voltage' },
        epc8226Frequency       => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.7', label => 'frequency' },
        epc8226PowerFactor     => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.8', label => 'power_factor' },
        epc8226Pangle          => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.9', label => 'phase_angle' },
        epc8226PowerApparent   => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.10', label => 'power_apparent' },
        epc8226PowerReactive   => { oid => '.1.3.6.1.4.1.28507.58.1.5.1.2.1.11', label => 'power_reactive' }
    };
    my $ovp_mapping = {
         epc8226OVPStatus => { oid => '.1.3.6.1.4.1.28507.58.1.5.2.1.2', label => 'ovp_status', map => $ovp_status_mapping }
    };
    my $ps_mapping = {
        epc8226PwrSupplyStatus => { oid => '.1.3.6.1.4.1.28507.58.1.5.13.1.2', label => 'ps_status', map => $ps_status_mapping }
    };

    my $global_results = $options{snmp}->get_leef( oids => [ $epc8226ActivePowerChan ], nothing_quit => 1);
    my $channels_results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $epc8226PowerEntry, start => $power_mapping->{epc8226ChanStatus}->{oid}, end => $power_mapping->{epc8226PowerReactive}->{oid} },
            { oid => $epc8226OVPEntry, start => $ovp_mapping->{epc8226OVPStatus}->{oid} },
            { oid => $epc8226PwrSupplyEntry, start => $ps_mapping->{epc8226PwrSupplyStatus}->{oid} }
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        active_channels => $global_results->{$epc8226ActivePowerChan}
    };

    my $power_result;
    foreach my $power_oid (keys %{$channels_results->{$epc8226PowerEntry}}) {
        next if ($power_oid !~ /^$power_mapping->{epc8226ChanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        $power_result->{$instance} = $options{snmp}->map_instance(mapping => $power_mapping, results => $channels_results->{$epc8226PowerEntry}, instance => $instance);
    };
    my $ovp_result;
    foreach my $ovp_oid (keys %{$channels_results->{$epc8226OVPEntry}}) {
        next if ($ovp_oid !~ /^$ovp_mapping->{epc8226OVPStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        $ovp_result->{$instance} = $options{snmp}->map_instance(mapping => $ovp_mapping, results => $channels_results->{$epc8226OVPEntry}, instance => $instance);
    };
    my $ps_result;
    foreach my $ps_oid (keys %{$channels_results->{$epc8226PwrSupplyEntry}}) {
        next if ($ps_oid !~ /^$ps_mapping->{epc8226PwrSupplyStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        $ps_result->{$instance} = $options{snmp}->map_instance(mapping => $ps_mapping, results => $channels_results->{$epc8226PwrSupplyEntry}, instance => $instance);
    };

    foreach my $channel_id (keys %{$power_result}) {
        next if (defined($self->{option_results}->{filter_channel}) &&  $channel_id !~ /$self->{option_results}->{filter_channel}/ );
        foreach my $stat (keys %{$power_result->{$channel_id}}) {
            if ($stat =~ m/epc8226Current|epc8226AbsEnergyActive|epc8226PowerFactor/ && defined($power_result->{$channel_id}->{$stat})) {
                $power_result->{$channel_id}->{$stat} *= 0.001;
            }
            if ($stat =~ m/epc8226Frequency|epc8226AbsEnergyActive/ && defined($power_result->{$channel_id}->{$stat})) {
                $power_result->{$channel_id}->{$stat} *= 0.01;
            }
            $self->{channels}->{$channel_id}->{display} = 'channel_' . $channel_id;
            $self->{channels}->{$channel_id}->{ $power_mapping->{$stat}->{label} } = $power_result->{$channel_id}->{$stat};
        }
        foreach my $stat (keys %{$ovp_result->{$channel_id}}) {
            $self->{channels}->{$channel_id}->{ $ovp_mapping->{$stat}->{label} } = $ovp_result->{$channel_id}->{$stat};
        }
        foreach my $stat (keys %{$ps_result->{$channel_id}}) {
            $self->{channels}->{$channel_id}->{ $ps_mapping->{$stat}->{label} } = $ps_result->{$channel_id}->{$stat};
        }
    }
}

1;

__END__

=head1 MODE

Check Gude UPC8226 Power Channels (banks) statistics.

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

=item B<--warning-ps-status>

Warning threshold for Power Supply status (Default: none)

=item B<--critical-ovp-status>

Critical threshold for Power Supply status (Default: '%{ps_status} !~ /up/i')

=item B<--warning-*>

Threshold warning.
Can be: 'active-channels', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=item B<--critical-*>

Can be: 'active-channels', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=back

=cut
