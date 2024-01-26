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

package hardware::pdu::gude::epc::snmp::mode::sppowerchannels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use hardware::pdu::gude::epc::snmp::mode::resources;

sub prefix_sp_output {
    my ($self, %options) = @_;

    return "Single port power channel interface '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sp', type => 1, cb_prefix_output => 'prefix_sp_output', message_multiple => 'All single port power channel interfaces are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-singleports', nlabel => 'pdu.singleport_power_channels.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => '%s single port(s)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sp} = [
        { label => 'state', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current', nlabel => 'pdu.interface.singleport_power_channel.current.ampere', set => {
                key_values => [ { name => 'current', no_value => 0 } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'energy', nlabel => 'pdu.interface.singleport_power_channel.energy.active.kilowatthour', set => {
                key_values => [ { name => 'abs_energy_active', no_value => 0 } ],
                output_template => 'absolute energy active: %.2f kWh',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'kWh', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'frequency', nlabel => 'pdu.interface.singleport_power_channel.frequency.hertz', set => {
                key_values => [ { name => 'frequency', no_value => 0 } ],
                output_template => 'frequency: %.2f Hz',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'Hz', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'phase-angle', nlabel => 'pdu.interface.singleport_power_channel.phase.angle.degree', set => {
                key_values => [ { name => 'phase_angle', no_value => 0 } ],
                output_template => 'phase angle: %.2f°',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'power-active', nlabel => 'pdu.power_channel.active.watt', set => {
                key_values => [ { name => 'power_active', no_value => 0 } ],
                output_template => 'active power: %.2f W',
                perfdatas => [
                    { template => '%.2f', unit => 'W', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'power-apparent', nlabel => 'pdu.interface.singleport_power_channel.power.apparent.voltampere', set => {
                key_values => [ { name => 'power_apparent', no_value => 0 } ],
                output_template => 'apparent power: %.2f VA',
                perfdatas => [
                    { template => '%.2f', unit => 'VA', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'power-factor', nlabel => 'pdu.interface.singleport_power_channel.power.factor.count', set => {
                key_values => [ { name => 'power_factor', no_value => 0 } ],
                output_template => 'power factor: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'power-reactive', nlabel => 'pdu.interface.singleport_power_channel.power.reactive.voltampere', set => {
                key_values => [ { name => 'power_reactive', no_value => 0 } ],
                output_template => 'reactive power: %.2f Var',
                perfdatas => [
                    { template => '%.2f', unit => 'Var', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'voltage', nlabel => 'pdu.interface.singleport_power_channel.voltage.volt', set => {
                key_values => [ { name => 'voltage', no_value => 0 } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'V', label_extra_instance => 1 }
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
        'filter-name:s'   => { name => 'filter_name' },
        'skip-poweredoff' => { name => 'skip_poweredoff' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $branch = hardware::pdu::gude::epc::snmp::mode::resources::find_gude_branch($self, snmp => $options{snmp});

    my $sp_state_mapping = {
        0 => 'off',
        1 => 'on'
    };
    my $sp_status_mapping = {
        0 => 'not active',
        1 => 'valid'
    };

    my $mapping = {
        state             => { oid => $branch .'.1.3.1.2.1.3', map => $sp_state_mapping },
        status            => { oid => $branch .'.1.5.5.2.1.2', map => $sp_status_mapping },
        abs_energy_active => { oid => $branch .'.1.5.5.2.1.3' },
        power_active      => { oid => $branch .'.1.5.5.2.1.4' },
        current           => { oid => $branch .'.1.5.5.2.1.5' },
        voltage           => { oid => $branch .'.1.5.5.2.1.6' },
        frequency         => { oid => $branch .'.1.5.5.2.1.7' },
        power_factor      => { oid => $branch .'.1.5.5.2.1.8' },
        phase_angle       => { oid => $branch .'.1.5.5.2.1.9' },
        power_apparent    => { oid => $branch .'.1.5.5.2.1.10' },
        power_reactive    => { oid => $branch .'.1.5.5.2.1.11' }
    };

    my $oid_name = $branch . '.1.3.1.2.1.2';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_name, nothing_quit => 1);

    $self->{global} = { total => 0 };
    $self->{sp} = {};
    my $duplicated = {};
    foreach (keys %$snmp_result) {
        /^$oid_name\.(.*)$/;
        my $id = $1;
        my $name = $snmp_result->{$_};
        $name = $snmp_result->{$_} . ':' . $id if (defined($duplicated->{$name}));
        if (defined($self->{sp}->{$name})) {
            $duplicated->{$name} = 1;
            my $instance = $self->{sp}->{$name}->{name} . ':' . $self->{sp}->{$name}->{instance};
            $self->{sp}->{$instance} = delete $self->{sp}->{$name};
            $name = $snmp_result->{$_} . ':' . $id;
        }
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        $self->{global}->{total}++;
        $self->{sp}->{$name} = { name => $name, instance => $id };
    }

    return if (scalar(keys %{$self->{sp}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values %{$self->{sp}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{sp}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{sp}->{$_}->{instance});
        if (defined($self->{option_results}->{skip_poweredoff}) && $result->{state} eq 'off') {
            $self->{global}->{total}--;
            delete $self->{sp}->{$_};
            next;
        }
        $result->{current} *= 0.001 if (defined($result->{current}));
        $result->{power_factor} *= 0.001 if (defined($result->{power_factor}));
        $result->{frequency} *= 0.01 if (defined($result->{frequency}));
        $result->{abs_energy_active} *= 0.01 if (defined($result->{abs_energy_active}));
        $self->{sp}->{$_} = { %$result, %{$self->{sp}->{$_}} };
    }
}

1;

__END__

=head1 MODE

Check single port power channels.

=over 8

=item B<--filter-name>

Filter single port power channels by name (can be a regexp).

=item B<--skip-poweredoff>

Exclude the single ports that have been powered off.

=item B<--warning-state>

Warning threshold for single port state.

=item B<--critical-state>

Critical threshold for single port state.

=item B<--warning-status>

Warning threshold for for single port status.

=item B<--critical-status>

Critical threshold for for single port status.

=item B<--warning-*>

Warning threshold.
Can be: 'active-channels', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=item B<--critical-*>

Can be: 'active-channels', 'current', 'energy', 'frequency', 'phase-angle', 'power-active',
'power-apparent', 'power-factor', 'power-reactive', 'voltage'

=back

=cut
