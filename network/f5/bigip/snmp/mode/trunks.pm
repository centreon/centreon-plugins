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

package network::f5::bigip::snmp::mode::trunks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} > 0) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    my $speed = $self->{result_values}->{speed} > 0 ? $self->{result_values}->{speed} : undef;

    $self->{output}->perfdata_add(
        label => 'traffic_' . $self->{result_values}->{label}, unit => 'b/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic_per_seconds}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $speed
    );
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} > 0) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        "traffic %s: %s/s (%s)",
        $self->{result_values}->{label},
        $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    my $diff_traffic = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});

    $self->{result_values}->{speed} = defined($self->{instance_mode}->{option_results}->{speed}) && $self->{instance_mode}->{option_results}->{speed} ne '' ? $self->{instance_mode}->{option_results}->{speed} : $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{speed}};
    $self->{result_values}->{speed} = $self->{result_values}->{speed} * 1000 * 1000; # bits
    $self->{result_values}->{traffic_per_seconds} = $diff_traffic * 8 / $options{delta_time};
    $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $self->{result_values}->{speed} if ($self->{result_values}->{speed} > 0);
    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_errors_perfdata {
    my ($self, %options) = @_;

    my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
    my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});

    $self->{output}->perfdata_add(
        label => 'packets_error_' . $self->{result_values}->{label}, unit => '%',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{errors_prct}),
        warning => $warning,
        critical => $critical,
        min => 0, max => 100
    );
}

sub custom_errors_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{errors_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
}

sub custom_errors_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "packets %s error: %s",
        $self->{result_values}->{label},
        defined($self->{result_values}->{errors_prct}) ? sprintf("%.2f%%", $self->{result_values}->{errors_prct}) : '-'
    );
}

sub custom_errors_calc {
    my ($self, %options) = @_;

    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{errors}})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    my $diff_errors = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{errors}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{errors}});
    my $diff_packets = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}});

    $self->{result_values}->{errors_prct} = ($diff_packets != 0) ? $diff_errors * 100 / $diff_packets : 0;
    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_drops_perfdata {
    my ($self, %options) = @_;
    
    my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
    my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    
    $self->{output}->perfdata_add(
        label => 'packets_drop_' . $self->{result_values}->{label}, unit => '%',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{drops_prct}),
        warning => $warning,
        critical => $critical,
        min => 0, max => 100
    );
}

sub custom_drops_threshold {
    my ($self, %options) = @_;
    
    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{drops_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
}

sub custom_drops_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "packets %s drop: %s",
        $self->{result_values}->{label}, 
        defined($self->{result_values}->{drops_prct}) ? sprintf("%.2f%%", $self->{result_values}->{drops_prct}) : '-'
    );
}

sub custom_drops_calc {
    my ($self, %options) = @_;
    
    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{drops}})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }
  
    my $diff_drops = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{drops}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{drops}});
    my $diff_packets = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{packets}});
    
    $self->{result_values}->{drops_prct} = ($diff_packets != 0) ? $diff_drops * 100 / $diff_packets : 0;
    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub port_trunk_output {
    my ($self, %options) = @_;

    return "checking trunk '" . $options{instance_value}->{display} . "'";
}

sub prefix_trunk_output {
    my ($self, %options) = @_;

    return "Trunk '" . $options{instance_value}->{display} . "' ";
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "interface '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        {
            name => 'trunks', type => 3, cb_prefix_output => 'prefix_trunk_output', cb_long_output => 'port_trunk_output', indent_long_output => '    ', message_multiple => 'All trunks are ok',
            group => [
                { name => 'trunk_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'interfaces', display_long => 1, cb_prefix_output => 'prefix_interface_output',  message_multiple => 'All interfaces are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{trunk_global} = [
        {
            label => 'status', type => 2, critical_default => '%{status} =~ /uninitialized|down/', 
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                output_template => "status is '%s'", output_error_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'sysTrunkStatBytesIn', diff => 1 }, { name => 'sysTrunkOperBw', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'),
                closure_custom_calc_extra_options => { label_ref => 'sysTrunkStatBytesIn', speed => 'sysTrunkOperBw', label => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic in: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'sysTrunkStatBytesOut', diff => 1 }, { name => 'sysTrunkOperBw', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'),
                closure_custom_calc_extra_options => { label_ref => 'sysTrunkStatBytesOut', speed => 'sysTrunkOperBw', label => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic out: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'packets-error-in', set => {
                key_values => [ { name => 'sysTrunkStatErrorsIn', diff => 1 }, { name => 'sysTrunkStatPktsIn', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => { errors => 'sysTrunkStatErrorsIn', packets => 'sysTrunkStatPktsIn', label => 'in' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets in error: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'packets-error-out', set => {
                key_values => [ { name => 'sysTrunkStatErrorsOut', diff => 1 }, { name => 'sysTrunkStatPktsOut', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => { errors => 'sysTrunkStatErrorsOut', packets => 'sysTrunkStatPktsOut', label => 'out' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets out error: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'packets-drop-in', set => {
                key_values => [ { name => 'sysTrunkStatDropsIn', diff => 1 }, { name => 'sysTrunkStatPktsIn', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_drops_calc'),
                closure_custom_calc_extra_options => { drops => 'sysTrunkStatDropsIn', packets => 'sysTrunkStatPktsIn', label => 'in' },
                closure_custom_output => $self->can('custom_drops_output'), output_error_template => 'packets in drop: %s',
                closure_custom_perfdata => $self->can('custom_drops_perfdata'),
                closure_custom_threshold_check => $self->can('custom_drops_threshold')
            }
        },
        { label => 'packets-drop-out', set => {
                key_values => [ { name => 'sysTrunkStatDropsOut', diff => 1 }, { name => 'sysTrunkStatPktsOut', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_drops_calc'),
                closure_custom_calc_extra_options => { drops => 'sysTrunkStatDropsOut', packets => 'sysTrunkStatPktsOut', label => 'out' },
                closure_custom_output => $self->can('custom_drops_output'), output_error_template => 'packets out drop: %s',
                closure_custom_perfdata => $self->can('custom_drops_perfdata'),
                closure_custom_threshold_check => $self->can('custom_drops_threshold')
            }
        },
        { label => 'interfaces-total', nlabel => 'trunk.interfaces.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total_interfaces' }, { name => 'display' } ],
                output_template => 'total interfaces: %s',
                perfdatas => [
                    { label => 'total_interfaces', template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'interface-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                output_template => "status is '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'   => { name => 'filter_name' },
        'units-traffic:s' => { name => 'units_traffic', default => '%' },
        'speed:s'         => { name => 'speed' },
        'add-interfaces'  => { name => 'add_interfaces' }
    });

    return $self;
}

my $map_trunk_status = {
    0 => 'up',
    1 => 'down',
    2 => 'disable',
    3 => 'uninitialized',
    4 => 'loopback',
    5 => 'unpopulated'
};
my $map_interface_status = {
    1 => 'up',
    2 => 'down',
    3 => 'testing',
    4 => 'unknown',
    5 => 'dormant',
    6 => 'notPresent',
    7 => 'lowerLayerDown'
};
my $mapping_interface = {
    display => { oid => '.1.3.6.1.2.1.2.2.1.2' }, # ifDescr
    status  => { oid => '.1.3.6.1.2.1.2.2.1.8', map => $map_interface_status }  # ifOperStatus
};

my $mapping = {
    status                => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.2', map => $map_trunk_status }, # sysTrunkStatus
    sysTrunkOperBw        => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.5' },
    sysTrunkStatPktsIn    => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.2' },
    sysTrunkStatBytesIn   => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.3' }, # Bytes
    sysTrunkStatPktsOut   => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.4' },
    sysTrunkStatBytesOut  => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.5' }, # Bytes
    sysTrunkStatErrorsIn  => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.8' },
    sysTrunkStatErrorsOut => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.9' },
    sysTrunkStatDropsIn   => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.10' },
    sysTrunkStatDropsOut  => { oid => '.1.3.6.1.4.1.3375.2.1.2.12.2.3.1.11' }
};

sub add_interfaces {
    my ($self, %options) = @_;

    my $interfaces = $options{snmp}->get_multiple_table(
        oids => [ { oid => $mapping_interface->{display}->{oid} }, { oid => $mapping_interface->{status}->{oid} } ],
        return_type => 1
    );

    my $oid_sysTrunkCfgMemberName = '.1.3.6.1.4.1.3375.2.1.2.12.3.2.1.2';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_sysTrunkCfgMemberName);
    foreach my $trunk_name (keys %{$self->{trunks}}) {
        $self->{trunks}->{$trunk_name}->{trunk_global}->{total_interfaces} = 0;
        foreach (keys %$snmp_result) {
            next if (! /^$oid_sysTrunkCfgMemberName\.$self->{trunks}->{$trunk_name}->{instance}\./);
            my $interface_name = $snmp_result->{$_};
            foreach my $oid_int (keys %$interfaces) {
                next if ($oid_int !~ /^$mapping_interface->{display}->{oid}\.(.*)/);
                my $instance = $1;
                next if ($interfaces->{$oid_int} ne $snmp_result->{$_});
                my $result = $options{snmp}->map_instance(mapping => $mapping_interface, results => $interfaces, instance => $instance);

                $self->{trunks}->{$trunk_name}->{interfaces}->{ $result->{display} } = {
                    %$result
                };
                $self->{trunks}->{$trunk_name}->{trunk_global}->{total_interfaces}++;
            }
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => 'Need to use SNMP v2c or v3.');
        $self->{output}->option_exit();
    }

    my $oid_sysTrunkName = '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.1';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_sysTrunkName, nothing_quit => 1);

    $self->{trunks} = {};
    foreach (keys %$snmp_result) {
        /^$oid_sysTrunkName\.(.*)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping trunk '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{trunks}->{ $snmp_result->{$_} } = {
            display => $snmp_result->{$_},
            instance => $instance,
            interfaces => {}
        };
    }

    if (scalar(keys %{$self->{trunks}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No trunk found.');
        $self->{output}->option_exit();
    }

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [map($_->{instance}, values(%{$self->{trunks}}))],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{trunks}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{trunks}->{$_}->{instance});
        $self->{trunks}->{$_}->{trunk_global} = {
            display => $_,
            %$result
        };
    }

    $self->add_interfaces(snmp => $options{snmp}) if (defined($self->{option_results}->{add_interfaces}));

    $self->{cache_name} = 'f5_bipgip_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check Trunks usage.

=over 8

=item B<--filter-name>

Filter by trunks name (regexp can be used).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--speed>

Set trunk speed in Mbps (Default: sysTrunkOperBw).
If not set and sysTrunkOperBw OID value is 0,
percentage thresholds will not be applied on traffic metrics.

=item B<--add-interfaces>

Monitor trunk interfaces.

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /uninitialized|down/').
Can used special variables like: %{status}, %{display}

=item B<--unknown-interface-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-interface-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-interface-status>

Set critical threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out', 'packets-error-in' (%),
'packets-error-out' (%), 'packets-drop-in' (%), 'packets-drop-out' (%),
'total-interfaces'.

=back

=cut
