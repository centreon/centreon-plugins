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
        'sim status: %s [imsi: %s] [interface state: %s]',
        $self->{result_values}->{simStatus},
        $self->{result_values}->{imsi},
        $self->{result_values}->{interfaceState}
    );
}

sub cell_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cellular radio module '%s' [sim icc: %s, operator: %s]",
        $options{instance_value}->{cellId},
        $options{instance_value}->{simIcc},
        $options{instance_value}->{operator}
    );
}

sub prefix_cell_output {
    my ($self, %options) = @_;

    return sprintf(
        "cellular radio module '%s' [sim icc: %s, operator: %s] ",
        $options{instance_value}->{cellId},
        $options{instance_value}->{simIcc},
        $options{instance_value}->{operator}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of cellular radio modules ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'cells', type => 3, cb_prefix_output => 'prefix_cell_output', cb_long_output => 'cell_long_output',
          indent_long_output => '    ', message_multiple => 'All cellular radio modules are ok',
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
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name'}
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{interfaceState} =~ /disconnect/',
            critical_default => '%{simStatus} =~ /LOCKED/ || %{simStatus} =~ /DETECTING/',
            set => {
                key_values => [
                    { name => 'cellId' }, { name => 'operator' }, { name => 'imsi' }, { name => 'simIcc' },
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
                key_values      => [ { name => 'rsrp' }, { name => 'cellId' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'rsrp: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-rsrq', nlabel => 'module.cellradio.rsrq.dbm', set => {
                key_values => [ { name => 'rsrq' }, { name => 'cellId' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'rsrq: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-snr', nlabel => 'module.cellradio.snr.db', set => {
                key_values => [ { name => 'snr' }, { name => 'cellId' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'snr: %s dB',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-rscp', nlabel => 'module.cellradio.rscp.dbm', set => {
                key_values => [ { name => 'rscp' }, { name => 'cellId' }, { name => 'simIcc' }, { name => 'operator' } ],
                output_template => 'rscp: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-csq', nlabel => 'module.cellradio.csq.dbm', set => {
                key_values => [ { name => 'csq' }, { name => 'cellId' }, { name => 'simIcc' }, { name => 'operator' } ],
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
        'filter-cell-id:s'            => { name => 'filter_cell_id' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(cellId) %(operator)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { cellId => 1, operator => 1, simIcc => 1}
    );
}

my $mapping_info_interface = {
    imei    => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.5' }, # teldatCellularInfoInterfaceModuleIMEI : Cellular module IMEI.
    imsi    => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.6' }, # teldatCellularInfoInterfaceModuleIMSI : Cellular module IMSI.
    simIcc   => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1.8' }, # teldatCellularInfoInterfaceSIMIcc : Cellular active SIM ICC.
};

my $mapping_state_interface = {
    interfaceState  => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.1.1.2' } # teldatCellularStateInterfaceState : Call state.
};

my $mapping_state_mobile = {
    techno      => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.6' }, # teldatCellularStateMobileRadioTechnology : Cellular mobile current radio access tecnology used (!GETRAT).
    rscp        => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.8' }, # teldatCellularStateMobileRxSignalCodePwr : Cellular mobile received signal code power (RSCP).
    csq         => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.10' }, # teldatCellularStateMobileSignalQuality : Cellular mobile reception signal quality (+CSQ).
    rsrp        => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.22' }, # teldatCellularStateMobileRxRSRP : Cellular mobile reference symbol received power (RSRP).
    rsrq        => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.23' }, # teldatCellularStateMobileRxRSRQ : Cellular mobile reference signal received quality (RSRQ).
    snr         => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.24' }, # teldatCellularStateMobileRxSINR : Cellular mobile signal versus noise ratio (SINR).
    simStatus   => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1.26' } # teldatCellularStateMobileSIMStatus : Cellular mobile SIM status.
};

my $mapping_prof_dial = {
    operator  => { oid => '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.4.1.2' } # teldatCellularProfDialName1 : Dial Profile Name(1) associated to cellular interface.
};

my $oid_teldatCellularInfoInterfaceEntry = '.1.3.6.1.4.1.2007.4.1.2.2.2.18.1.1'; # teldatInfoInterfaceTable
my $oid_teldatCellularStateMobileEntry = '.1.3.6.1.4.1.2007.4.1.2.2.2.18.3.2.1'; # teldatStateMobileTable

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0 };
    $self->{cells} = {};

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping_state_interface->{interfaceState}->{oid} },
            { oid => $mapping_prof_dial->{operator}->{oid} },
            { oid => $oid_teldatCellularInfoInterfaceEntry, start => $mapping_info_interface->{imei}->{oid}, end => $mapping_info_interface->{simIcc}->{oid} },
            { oid => $oid_teldatCellularStateMobileEntry, start => $mapping_state_mobile->{techno}->{oid}, end => $mapping_state_mobile->{simStatus}->{oid} }
        ],
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result->{$oid_teldatCellularInfoInterfaceEntry}}) {
        next if ($oid !~ /^$mapping_info_interface->{imei}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_info_interface, results => $snmp_result->{$oid_teldatCellularInfoInterfaceEntry}, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping_state_interface, results => $snmp_result->{$mapping_state_interface->{interfaceState}->{oid}}, instance => $instance);
        my $result3 = $options{snmp}->map_instance(mapping => $mapping_prof_dial, results => $snmp_result->{$mapping_prof_dial->{operator}->{oid}}, instance => $instance);

        my $cell_id = $result->{imei};
        next if ($cell_id !~ /^(?:[0-9]+)$/);
        next if (defined($self->{option_results}->{filter_cell_id}) && $self->{option_results}->{filter_cell_id} ne '' &&
            $cell_id !~ /$self->{option_results}->{filter_cell_id}/ && $result->{simIcc} !~ /$self->{option_results}->{filter_cell_id}/);

        my $operator = $result3->{operator};
        if($result3->{operator} =~ /^-+$/){
            $operator = "N/A";
        }
        $self->{cells}->{$instance} = {
            cellId => $cell_id,
            simIcc  => $result->{simIcc},
            operator => $operator,
            status => {
                cellId => $cell_id,
                simIcc  => $result->{simIcc},
                operator => $operator,
                imsi   => $result->{imsi},
                interfaceState => $result2->{interfaceState}
            },
            signal => {
                cellId => $cell_id,
                simIcc  => $result->{simIcc},
                operator => $operator
            }
        };
    }

    if (scalar(keys %{$self->{cells}}) <= 0 && defined($self->{option_results}->{filter_cell_id}) && $self->{option_results}->{filter_cell_id} ne '') {
        $self->{output}->add_option_msg(short_msg => "No Cell ID found matching with filter : ".$self->{option_results}->{filter_cell_id});
        $self->{output}->option_exit();
    }
    # Return : OK:  | 'modules.cellradio.detected.count'=0;;;0;
    # return if (scalar(keys %{$self->{cells}}) <= 0);

    foreach my $instance (keys %{$self->{cells}}) {
        my $result4 = $options{snmp}->map_instance(mapping => $mapping_state_mobile, results => $snmp_result->{$oid_teldatCellularStateMobileEntry}, instance => $instance);

        $self->{cells}->{$instance}->{status}->{simStatus} = $result4->{simStatus};

        if ($self->{cells}->{$instance}->{status}->{simIcc} ne '') {
            if($result4->{rsrp} ne '' && $result4->{rsrp} ne 0){
                $self->{cells}->{$instance}->{signal}->{rsrp} = $result4->{rsrp};
            }
            if($result4->{rsrq} ne '' && $result4->{rsrq} ne 0) {
                $self->{cells}->{$instance}->{signal}->{rsrq} = $result4->{rsrq};
            }
            if($result4->{snr} ne '' && $result4->{snr} ne 0) {
                $self->{cells}->{$instance}->{signal}->{snr} = $result4->{snr};
            }
            if($result4->{rscp} ne '' && $result4->{rscp} ne 0) {
                $self->{cells}->{$instance}->{signal}->{rscp} = $result4->{rscp};
            }
            if($result4->{csq} ne '' && $result4->{csq} ne 0) {
                $self->{cells}->{$instance}->{signal}->{csq} = $result4->{csq};
            }
        }

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check cellular radio modules.

=over 8

=item B<--filter-cell-id>

Filter cell modules by IMEI ID.

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(cellId) %(operator)').
You can use the following variables: %{cellId}, %{simIcc}, %{operator}

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{simStatus}, %{interfaceState}, %{cellId}, %{simIcc}, %{operator}, %{imsi}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{interfaceState} =~ /disconnect/').
You can use the following variables: %{simStatus}, %{interfaceState}, %{cellId}, %{simIcc}, %{operator}, %{imsi}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{simStatus} =~ /LOCKED/ || %{simStatus} =~ /DETECTING/').
You can use the following variables: %{simStatus}, %{interfaceState}, %{cellId}, %{simIcc}, %{operator}, %{imsi}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'modules-cellradio-detected', 'module-cellradio-rsrp', ''module-cellradio-rsrq', 'module-cellradio-rscp', 'module-cellradio-csq'
'module-cellradio-snr'.

=back

=cut
