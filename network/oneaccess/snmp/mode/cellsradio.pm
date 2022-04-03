#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package network::oneaccess::snmp::mode::cellsradio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_signal_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{cellId},
            $self->{result_values}->{operator}
        ],
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'sim status: %s [imsi: %s] [signal quality: %s]',
        $self->{result_values}->{simStatus},
        $self->{result_values}->{imsi},
        $self->{result_values}->{signalQuality}
    );
}

sub cell_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cellular radio module '%s' [operator: %s]",
        $options{instance_value}->{cellId}, 
        $options{instance_value}->{operator}
    );
}

sub prefix_cell_output {
    my ($self, %options) = @_;

    return sprintf(
        "cellular radio module '%s' [operator: %s] ",
        $options{instance_value}->{cellId}, 
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
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{signalQuality} =~ /poor/',
            critical_default => '%{simStatus} eq "notPresent" || %{signalQuality} =~ /none/',
            set => {
                key_values => [
                    { name => 'cellId' }, { name => 'operator' }, { name => 'imsi' },
                    { name => 'simStatus' }, { name => 'signalQuality' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                output_template => "sim status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{signal} = [
        { label => 'module-cellradio-rsrp', nlabel => 'module.cellradio.rsrp.dbm', set => {
                key_values => [ { name => 'rsrp' }, { name => 'cellId' }, { name => 'operator' } ],
                output_template => 'rsrp: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-rssi', nlabel => 'module.cellradio.rssi.dbm', set => {
                key_values => [ { name => 'rssi' }, { name => 'cellId' }, { name => 'operator' } ],
                output_template => 'rssi: %s dBm',
                closure_custom_perfdata => $self->can('custom_signal_perfdata')
            }
        },
        { label => 'module-cellradio-snr', nlabel => 'module.cellradio.snr.db', set => {
                key_values => [ { name => 'snr' }, { name => 'cellId' }, { name => 'operator' } ],
                output_template => 'snr: %s dB',
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
        'filter-cell-id:s'  => { name => 'filter_cell_id' }
    });

    return $self;
}

my $mapping_id = {
    imei => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.14' }, # oacCellIMEI
    meid => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.15' }  # oacCellMEID
};
my $mapping = {
    simStatus => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.20' }, # oacCellSIMStatus
    imsi      => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.21' }, # oacCellIMSI
    operator  => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.40' }, # oacCellSelectedOperator
    rssi      => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.41' }, # oacCellSignalStrength
    rsrp      => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.44' }, # oacCellRSRP
    snr       => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.45' }, # oacCellSNR
    techno    => { oid => '.1.3.6.1.4.1.13191.10.3.9.2.1.46' }  # oacCellRadioAccessTechnology
};

sub get_signal_quality {
    my ($self, %options) = @_;

    my $quality = '-';
    if ($options{techno} =~ /4G/) {
        if ($options{rsrp} < -140) {
            $quality = 'none';
        } elsif ($options{rsrp} < -120) {
            $quality = 'poor';
        } elsif ($options{rsrp} < -105) {
            $quality = 'fair';
        } elsif ($options{rsrp} < -90) {
            $quality = 'good';
        } else {
            $quality = 'excellent';
        }
    } elsif ($options{techno} =~ /3G/) {
        if ($options{rssi} < -111) {
            $quality = 'none';
        } elsif ($options{rssi} < -105) {
            $quality = 'poor';
        } elsif ($options{rssi} < -99) {
            $quality = 'fair';
        } elsif ($options{rssi} < -89) {
            $quality = 'good';
        } else {
            $quality = 'excellent';
        }
    } elsif ($options{techno} =~ /2G/) {
        if ($options{rssi} < -111) {
            $quality = 'none';
        } elsif ($options{rssi} < -95) {
            $quality = 'poor';
        } elsif ($options{rssi} < -85) {
            $quality = 'fair';
        } elsif ($options{rssi} < -75) {
            $quality = 'good';
        } else {
            $quality = 'excellent';
        }
    } 

    return $quality;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0 };
    $self->{cells} = {};

    my $oid_radioTable = '.1.3.6.1.4.1.13191.10.3.9.2'; # oacCellRadioModuleTable
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_radioTable,
        start => $mapping_id->{imei}->{oid},
        end => $mapping_id->{meid}->{oid},
        nothing_quit => 1
    );
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_id->{imei}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_id, results => $snmp_result, instance => $instance);

        my $cell_id = $result->{imei} =~ /^(?:[0-9]+)$/ ? $result->{imei} : $result->{meid};
        next if (defined($self->{option_results}->{filter_cell_id}) && $self->{option_results}->{filter_cell_id} ne '' &&
            $cell_id !~ /$self->{option_results}->{filter_cell_id}/);

        $self->{cells}->{$instance} = {
            cellId => $cell_id,
            status => { cellId => $cell_id },
            signal => { cellId => $cell_id }
        };
    }

    return if (scalar(keys %{$self->{cells}}) <= 0);
    
    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_, keys %{$self->{cells}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{cells}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{cells}->{$_}->{operator} = $result->{operator};
        $self->{cells}->{$_}->{status}->{operator} = $result->{operator};
        $self->{cells}->{$_}->{status}->{imsi} = defined($result->{imsi}) && $result->{imsi} =~ /^(?:[0-9]+)$/ ? $result->{imsi} : '-';
        $self->{cells}->{$_}->{signal}->{operator} = $result->{operator};

        $self->{cells}->{$_}->{status}->{simStatus} = $result->{simStatus} =~ /is present/ ? 'present' : 'notPresent';
        $self->{cells}->{$_}->{status}->{signalQuality} = $self->get_signal_quality(
            techno => $result->{techno},
            rsrp => $result->{rsrp},
            rssi => $result->{rssi}
        );

        if ($self->{cells}->{$_}->{status}->{simStatus} eq 'present') {
            $self->{cells}->{$_}->{signal}->{rssi} = $result->{rssi};
            $self->{cells}->{$_}->{signal}->{rsrp} = $result->{rsrp};
            $self->{cells}->{$_}->{signal}->{snr} = $result->{snr};
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

Filter cell modules by id (IMEI or MEID).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{simStatus}, %{signalQuality}, %{cellId}, %{operator}, %{imsi}

=item B<--warning-status>

Set warning threshold for status (Default: '%{signalQuality} =~ /poor/').
Can used special variables like: %{simStatus}, %{signalQuality}, %{cellId}, %{operator}, %{imsi}

=item B<--critical-status>

Set critical threshold for status (Default: '%{simStatus} eq "notPresent" || %{signalQuality} =~ /none/').
Can used special variables like: %{simStatus}, %{signalQuality}, %{cellId}, %{operator}, %{imsi}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'modules-cellradio-detected', 'module-cellradio-rsrp', 
'module-cellradio-rssi', 'module-cellradio-snr'.

=back

=cut
