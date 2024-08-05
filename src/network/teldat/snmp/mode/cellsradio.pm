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

package network::teldat::snmp::mode::cellsradio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_signal_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $instances,
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'sim status: %s [operator: %s] [imsi: %s] [interface state: %s] [simIcc: %s]',
        $self->{result_values}->{simStatus},
        $self->{result_values}->{operator},
        $self->{result_values}->{imsi},
        $self->{result_values}->{interfaceState},
        $self->{result_values}->{simIcc}
    );
}

sub cell_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cellular radio module '%s' interface '%s' [imei: %s] ",
        $options{instance_value}->{module_num},
        $options{instance_value}->{interfaceType},
        $options{instance_value}->{imei}
    );
}

sub prefix_cell_output {
    my ($self, %options) = @_;

    return sprintf(
        "cellular radio module '%s' interface '%s' [imei: %s] ",
        $options{instance_value}->{module_num},
        $options{instance_value}->{interfaceType},
        $options{instance_value}->{imei}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of cellular radio interfaces';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'cells', type => 3, cb_prefix_output => 'prefix_cell_output', cb_long_output => 'cell_long_output',
          indent_long_output => '    ', message_multiple => 'All cellular radio interfaces are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'signal', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'modules-cellradio-detected', display_ok => 0, nlabel => 'modules.cellradio.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{interfaceState} =~ /disconnect/ && %{interfaceType} =~ /data primary/',
            set => {
                key_values => [
                    { name => 'module' }, { name => 'interfaceType' }, { name => 'imei' }, { name => 'simIcc' },
                    { name => 'operator' }, { name => 'imsi' }, 
                    { name => 'simStatus' }, { name => 'interfaceState' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{signal} = [
        { label => 'module-cellradio-rsrp', nlabel => 'module.cellradio.rsrp.dbm', set => {
                key_values      => [ { name => 'rsrp' }, { name => 'module' }, { name => 'interfaceType' }, { name => 'imei' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'rsrp: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-rsrq', nlabel => 'module.cellradio.rsrq.dbm', set => {
                key_values => [ { name => 'rsrq' }, { name => 'module' }, { name => 'interfaceType' }, { name => 'imei' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'rsrq: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-snr', nlabel => 'module.cellradio.snr.db', set => {
                key_values => [ { name => 'snr' }, { name => 'module' }, { name => 'interfaceType' }, { name => 'imei' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'snr: %s dB',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-rscp', nlabel => 'module.cellradio.rscp.dbm', set => {
                key_values => [ { name => 'rscp' }, { name => 'module' }, { name => 'interfaceType' }, { name => 'imei' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'rscp: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-csq', nlabel => 'module.cellradio.csq.dbm', set => {
                key_values => [ { name => 'csq' }, { name => 'module' }, { name => 'interfaceType' }, { name => 'imei' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'csq: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-module:s'             => { name => 'filter_module' },
        'filter-imei:s'               => { name => 'filter_imei' },
        'filter-interface-type:s'     => { name => 'filter_interface_type' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(module) %(interfaceType) %(imei)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { module => 1, interfaceType => 1, imei => 1, imsi => 1, operator => 1, simIcc => 1}
    );
}

my $mapping_info_interface = {
    imei   => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.5' }, # teldatCellularInfoInterfaceModuleIMEI : Cellular module IMEI.
    imsi   => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.6' }, # teldatCellularInfoInterfaceModuleIMSI : Cellular module IMSI.
    simIcc => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.8' } # teldatCellularInfoInterfaceSIMIcc : Cellular active SIM ICC.
};

my $mapping_data_interface = {
    interfaceState => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.1.1.2' }, # teldatCellularStateInterfaceState : Call state.
    techno         => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.6' }, # teldatCellularStateMobileRadioTechnology : Cellular mobile current radio access tecnology used (!GETRAT).
    rscp           => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.8' }, # teldatCellularStateMobileRxSignalCodePwr : Cellular mobile received signal code power (RSCP).
    csq            => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.10' }, # teldatCellularStateMobileSignalQuality : Cellular mobile reception signal quality (+CSQ).
    rsrp           => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.22' }, # teldatCellularStateMobileRxRSRP : Cellular mobile reference symbol received power (RSRP).
    rsrq           => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.23' }, # teldatCellularStateMobileRxRSRQ : Cellular mobile reference signal received quality (RSRQ).
    snr            => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.24' }, # teldatCellularStateMobileRxSINR : Cellular mobile signal versus noise ratio (SINR).
    simStatus      => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.26' }, # teldatCellularStateMobileSIMStatus : Cellular mobile SIM status.
    operator       => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.4.1.2' }
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
        start => $mapping_info_interface->{imei}->{oid},
        end => $mapping_info_interface->{simIcc}->{oid},
        nothing_quit => 1
    );

    $self->{global} = { detected => 0 };
    $self->{cells} = {};
    my $modules = {};
    my $module_num = 0;
    my $interface_type = 0;
    foreach my $oid ($options{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping_info_interface->{imei}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_info_interface, results => $snmp_result, instance => $instance);
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

        next if (defined($self->{option_results}->{filter_module}) && $self->{option_results}->{filter_module} ne '' &&
            $module !~ /$self->{option_results}->{filter_module}/);
        next if (defined($self->{option_results}->{filter_imei}) && $self->{option_results}->{filter_imei} ne '' &&
            $result->{imei} !~ /$self->{option_results}->{filter_imei}/);
        next if (defined($self->{option_results}->{filter_interface_type}) && $self->{option_results}->{filter_interface_type} ne '' &&
             $interface_types->{$interface_type} !~ /$self->{option_results}->{filter_interface_type}/);

        $self->{cells}->{$instance} = {
            module => $module,
            module_num => $module_num,
            interfaceType => $interface_types->{$interface_type},
            imei => $result->{imei},
            status => {
                module => $module,
                interfaceType => $interface_types->{$interface_type},
                imei => $result->{imei},
                imsi => $result->{imsi},
                simIcc  => $result->{simIcc}
            },
            signal => {
                module => $module,
                interfaceType => $interface_types->{$interface_type},
                imei => $result->{imei},
                imsi => $result->{imsi},
                simIcc  => $result->{simIcc}
            }
        };

        $self->{global}->{detected}++;
    }

    if (scalar(keys %{$self->{cells}}) <= 0 &&
        (defined($self->{option_results}->{filter_module}) && $self->{option_results}->{filter_module} ne '') ||
        (defined($self->{option_results}->{filter_imei}) && $self->{option_results}->{filter_imei} ne '')) {
        $self->{output}->add_option_msg(short_msg => 'No interfaces found matching with filter');
        $self->{output}->option_exit();
    }
 
    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_data_interface)) ],
        instances => [ map($_, keys(%{$self->{cells}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
 
    foreach (keys %{$self->{cells}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping_data_interface, results => $snmp_result, instance => $_);

        $self->{cells}->{$_}->{status}->{simStatus} = $result->{simStatus};
        $self->{cells}->{$_}->{status}->{interfaceState} = $result->{interfaceState};
        $self->{cells}->{$_}->{status}->{operator} = $result->{operator};
        $self->{cells}->{$_}->{signal}->{operator} = $result->{operator};

        next if ($self->{cells}->{$_}->{status}->{simIcc} eq '');

        $self->{cells}->{$_}->{signal}->{rsrp} = $result->{rsrp} if ($result->{rsrp} ne '' && $result->{rsrp} != 0);
        $self->{cells}->{$_}->{signal}->{rsrq} = $result->{rsrq} if ($result->{rsrq} ne '' && $result->{rsrq} != 0);
        $self->{cells}->{$_}->{signal}->{snr} = $result->{snr} if ($result->{snr} ne '' && $result->{snr} != 0);
        $self->{cells}->{$_}->{signal}->{rscp} = $result->{rscp} if ($result->{rscp} ne '' && $result->{rscp} != 0);
        $self->{cells}->{$_}->{signal}->{csq} = $result->{csq} if ($result->{csq} ne '' && $result->{csq} != 0);
    }
 }

1;

__END__

=head1 MODE

Check cellular radio interfaces.

=over 8

=item B<--filter-module>

Filter cellular radio interfaces by module.

=item B<--filter-imei>

Filter cellular radio interfaces by IMEI.

=item B<--filter-interface-type>

Filter cellular radio interfaces by type.

=item B<--custom-perfdata-instances>

Customize the name composition rule for the instances the metrics will be attached to (default: '%(module) %(interfaceType) %(imei)').
You can use the following variables: %(module), %(interfaceType), %(imei), %(operator), %(simIcc)

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{module}, %{interfaceType}, %{imei}, %{operator}, %{imsi}, %{simIcc}, %{simStatus}, %{interfaceState}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{interfaceState} =~ /disconnect/ && %{interfaceType} =~ /data primary/').
You can use the following variables: %{module}, %{interfaceType}, %{imei}, %{operator}, %{imsi}, %{simIcc}, %{simStatus}, %{interfaceState}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{module}, %{interfaceType}, %{imei}, %{operator}, %{imsi}, %{simIcc}, %{simStatus}, %{interfaceState}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'modules-cellradio-detected', 'module-cellradio-rsrp', ''module-cellradio-rsrq', 'module-cellradio-rscp', 'module-cellradio-csq'
'module-cellradio-snr'.

=back

=cut
