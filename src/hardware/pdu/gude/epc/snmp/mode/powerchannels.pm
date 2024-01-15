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

package hardware::pdu::gude::epc::snmp::mode::powerchannels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use hardware::pdu::gude::epc::snmp::mode::resources;

sub prefix_channels_output {
    my ($self, %options) = @_;

    return "Power channel interface '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'channels', type => 1, cb_prefix_output => 'prefix_channels_output', message_multiple => 'All power channel interfaces are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active-channels', nlabel => 'pdu.power_channels.active.count', set => {
                key_values => [ { name => 'active_channels' } ],
                output_template => '%s active power channel(s)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{channels} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /valid/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'ovp-status', type => 2, critical_default => '%{ovp_status} !~ /ok/i', set => {
                key_values => [ { name => 'ovp_status' }, { name => 'name' } ],
                output_template => 'ovp status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'ps-status', type => 2, critical_default => '%{ps_status} !~ /up/i', set => {
                key_values => [ { name => 'ps_status' }, { name => 'name' } ],
                output_template => 'power supply status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current', nlabel => 'pdu.interface.power_channel.current.ampere', set => {
                key_values => [ { name => 'current', no_value => 0 }, { name => 'name' } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'energy', nlabel => 'pdu.interface.power_channel.energy.active.kilowatthour', set => {
                key_values => [ { name => 'abs_energy_active', no_value => 0 }, { name => 'name' } ],
                output_template => 'absolute energy active: %.2f kWh',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'kWh', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'frequency', nlabel => 'pdu.interface.power_channel.frequency.hertz', set => {
                key_values => [ { name => 'frequency', no_value => 0 }, { name => 'name' } ],
                output_template => 'frequency: %.2f Hz',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'Hz', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'phase-angle', nlabel => 'pdu.interface.power_channel.phase.angle.degree', set => {
                key_values => [ { name => 'phase_angle', no_value => 0 }, { name => 'name' } ],
                output_template => 'phase angle: %.2f°',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'power-active', nlabel => 'pdu.interface.power_channel.active.watt', set => {
                key_values => [ { name => 'power_active', no_value => 0 }, { name => 'name' } ],
                output_template => 'active power: %.2f W',
                perfdatas => [
                    { template => '%.2f', unit => 'W', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'power-apparent', nlabel => 'pdu.interface.power_channel.power.apparent.voltampere', set => {
                key_values => [ { name => 'power_apparent', no_value => 0 }, { name => 'name' } ],
                output_template => 'apparent power: %.2f VA',
                perfdatas => [
                    { template => '%.2f', unit => 'VA', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'power-factor', nlabel => 'pdu.interface.power_channel.power.factor.count', set => {
                key_values => [ { name => 'power_factor', no_value => 0 }, { name => 'name' } ],
                output_template => 'power factor: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'power-reactive', nlabel => 'pdu.interface.power_channel.power.reactive.voltampere', set => {
                key_values => [ { name => 'power_reactive', no_value => 0 }, { name => 'name' } ],
                output_template => 'reactive power: %.2f Var',
                perfdatas => [
                    { template => '%.2f', unit => 'Var', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'voltage', nlabel => 'pdu.interface.power_channel.voltage.volt', set => {
                key_values => [ { name => 'voltage', no_value => 0 }, { name => 'name' } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'V', label_extra_instance => 1, instance_use => 'name' }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $branch = hardware::pdu::gude::epc::snmp::mode::resources::find_gude_branch($self, snmp => $options{snmp});

    my $channel_status_mapping = {
        0 => 'not active', 1 => 'valid'
    };
    my $ovp_status_mapping = {
        0 => 'failure', 1 => 'ok', 2 => 'unknown'
    };
    my $ps_status_mapping = {
        0 => 'down', 1 => 'up'
    };
    my $mapping = {
        status            => { oid => $branch .'.1.5.1.2.1.2', map => $channel_status_mapping },
        abs_energy_active => { oid => $branch .'.1.5.1.2.1.3' },
        power_active      => { oid => $branch .'.1.5.1.2.1.4' },
        current           => { oid => $branch .'.1.5.1.2.1.5' },
        voltage           => { oid => $branch .'.1.5.1.2.1.6' },
        frequency         => { oid => $branch .'.1.5.1.2.1.7' },
        power_factor      => { oid => $branch .'.1.5.1.2.1.8' },
        phase_angle       => { oid => $branch .'.1.5.1.2.1.9' },
        power_apparent    => { oid => $branch .'.1.5.1.2.1.10' },
        power_reactive    => { oid => $branch .'.1.5.1.2.1.11' },
        ovp_status        => { oid => $branch .'.1.5.2.1.2', map => $ovp_status_mapping },
        ps_status         => { oid => $branch .'.1.5.13.1.2', map => $ps_status_mapping }
    };

    my $oid_name = $branch . '.1.5.1.2.1.100';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_name, nothing_quit => 1);

    $self->{global} = { active_channels => 0 };
    $self->{channels} = {};
    foreach (keys %$snmp_result) {
        /^$oid_name\.(.*)$/;
        my $instance = $1;
        my $name = defined($snmp_result->{$_}) && $snmp_result->{$_} ne '' ? $snmp_result->{$_} : $instance;
        $self->{global}->{active_channels}++;
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        $self->{channels}->{$instance} = { name => $name };
    }

    return if (scalar(keys %{$self->{channels}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_, keys %{$self->{channels}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{channels}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        $result->{current} *= 0.001 if (defined($result->{current}));
        $result->{power_factor} *= 0.001 if (defined($result->{power_factor}));
        $result->{frequency} *= 0.01 if (defined($result->{frequency}));
        $result->{abs_energy_active} *= 0.01 if (defined($result->{abs_energy_active}));
        $self->{channels}->{$_} = { %$result, %{$self->{channels}->{$_}} };
    }
}

1;

__END__

=head1 MODE

Check power channel interfaces.

=over 8

=item B<--filter-name>

Filter power channel interfaces by name (can be a regexp).

=item B<--warning-status>

Warning threshold for channel status.

=item B<--critical-status>

Critical threshold for channel status (default: '%{status} !~ /valid/i')

=item B<--warning-ovp-status>

Warning threshold for OVP (OverVoltage Protection) status.

=item B<--critical-ovp-status>

Critical threshold for OVP (OverVoltage Protection) status (default: '%{ovp_status} !~ /ok/i')

=item B<--warning-ps-status>

Warning threshold for power supply status.

=item B<--critical-ps-status>

Critical threshold for power supply status (default: '%{ps_status} !~ /up/i')

=item B<--warning-*>

Warning threshold.
Can be: 'active-channels', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=item B<--critical-*>

Can be: 'active-channels', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=back

=cut
