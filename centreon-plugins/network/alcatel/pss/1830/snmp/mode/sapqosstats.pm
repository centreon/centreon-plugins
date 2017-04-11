#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::alcatel::pss::1830::snmp::mode::sapqosstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

my $instance_mode;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sap', type => 1, cb_prefix_output => 'prefix_sap_output', message_multiple => 'All SAP QoS are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{sap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'admin' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'in-traffic', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'display' } ],
                per_second => 1,
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_qos_output'),
                closure_custom_perfdata => $self->can('custom_qos_perfdata'),
                closure_custom_threshold_check => $self->can('custom_qos_threshold'),
            }
        },
        { label => 'out-traffic', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'display' } ],
                per_second => 1,
                closure_custom_calc => $self->can('custom_qos_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_qos_output'),
                closure_custom_perfdata => $self->can('custom_qos_perfdata'),
                closure_custom_threshold_check => $self->can('custom_qos_threshold'),
            }
        },
        { label => 'in-drop-packets', set => {
                key_values => [ { name => 'in_dropped_packets', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_qos_drop_calc'),
                output_template => 'In Dropped Packets : %s',
                perfdatas => [
                    { label => 'in_drop_packets', value => 'in_dropped_packets_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        my $label = $self->{label};
        $label =~ s/-/_/g;
        if (defined($instance_mode->{option_results}->{'critical_' . $label}) && $instance_mode->{option_results}->{'critical_' . $label} ne '' &&
            eval "$instance_mode->{option_results}->{'critical_' . $label}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{'warning_' . $label}) && $instance_mode->{option_results}->{'warning_' . $label} ne '' &&
                 eval "$instance_mode->{option_results}->{'warning_' . $label}") {
            $status = 'warning';
        }

        $instance_mode->{last_status} = 0;
        if ($self->{result_values}->{admin} eq 'up') {
            $instance_mode->{last_status} = 1;
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ' . $self->{result_values}->{status} . ' (admin: ' . $self->{result_values}->{admin} . ')';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{admin} = $options{new_datas}->{$self->{instance} . '_admin'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_qos_perfdata {
    my ($self, %options) = @_;
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    
    my ($warning, $critical);
    if ($instance_mode->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($instance_mode->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label});
    }
    
    $self->{output}->perfdata_add(label => 'traffic_' . $self->{result_values}->{label} . $extra_label, unit => 'b/s',
                                  value => sprintf("%.2f", $self->{result_values}->{traffic}),
                                  warning => $warning,
                                  critical => $critical,
                                  min => 0, max => $self->{result_values}->{speed});
}

sub custom_qos_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($instance_mode->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    } elsif ($instance_mode->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_qos_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic}, network => 1);
    my ($total_value, $total_unit);
    if (defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} =~ /[0-9]/) {
        ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{speed}, network => 1);
    }
   
    my $msg = sprintf("Traffic %s : %s/s (%s on %s)",
                      ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-',
                      defined($total_value) ? $total_value . $total_unit : '-');
    return $msg;
}

sub custom_qos_calc {
    my ($self, %options) = @_;
    
    return -10 if (defined($instance_mode->{last_status}) && $instance_mode->{last_status} == 0);
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic} = ($options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}} - $options{old_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}}) / $options{delta_time};
    if (defined($instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}}) && $instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}} =~ /[0-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / ($instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000);
        $self->{result_values}->{speed} = $instance_mode->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000;
    }
    return 0;
}

sub custom_qos_drop_calc {
    my ($self, %options) = @_;
    
    return -10 if (defined($instance_mode->{last_status}) && $instance_mode->{last_status} == 0);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{in_dropped_packets_absolute} = $options{new_datas}->{$self->{instance} . '_in_dropped_packets'} - $options{old_datas}->{$self->{instance} . '_in_dropped_packets'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "display-name:s"      => { name => 'display_name', default => '%{SysSwitchId}.%{SvcId}.%{SapPortId}.%{SapEncapValue}' },
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "speed-in:s"          => { name => 'speed_in' },
                                  "speed-out:s"         => { name => 'speed_out' },
                                  "units-traffic:s"     => { name => 'units_traffic', default => '%' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{admin} =~ /up/i and %{status} !~ /up/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub prefix_sap_output {
    my ($self, %options) = @_;
    
    return "SAP '" . $options{instance_value}->{display} . "' ";
}

sub get_display_name {
    my ($self, %options) = @_;
    
    my $display_name = $self->{option_results}->{display_name};
    $display_name =~ s/%\{(.*?)\}/$options{$1}/ge;
    return $display_name;
}

my %map_admin = (1 => 'up', 2 => 'down');
my %map_oper = (1 => 'up', 2 => 'down', 3 => 'ingressQosMismatch',
    4 => 'egressQosMismatch', 5 => 'portMtuTooSmall', 6 => 'svcAdminDown',
    7 => 'iesIfAdminDown'
);

my $mapping = {
    tnSapAdminStatus    => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.2.1.6', map => \%map_admin },
    tnSapOperStatus     => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.2.1.7', map => \%map_oper },
    tnSapBaseStatsIngressForwardedOctets    => { oid => '.1.3.6.1.4.1.7483.7.2.2.2.8.1.1.1.4' },
    tnSapBaseStatsEgressForwardedOctets     => { oid => '.1.3.6.1.4.1.7483.7.2.2.2.8.1.1.1.6' },
    tnSapBaseStatsIngressDroppedPackets     => { oid => '.1.3.6.1.4.1.7483.7.2.2.2.8.1.1.1.9' },
};

my $oid_tnSapDescription = '.1.3.6.1.4.1.7483.6.1.2.4.3.2.1.5';
my $oid_tnSvcName = '.1.3.6.1.4.1.7483.6.1.2.4.2.2.1.28';

sub manage_selection {
    my ($self, %options) = @_;
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    # SNMP Get is slow for Dropped, Ingress, Egress. So we are doing in 2 times.
    $self->{sap} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $oid_tnSapDescription }, 
            { oid => $oid_tnSvcName },
        ],
        nothing_quit => 1);
    
    foreach my $oid (keys %{$snmp_result->{$oid_tnSapDescription}}) {
        next if ($oid !~ /^$oid_tnSapDescription\.(.*?)\.(.*?)\.(.*?)\.(.*?)$/);
        my ($SysSwitchId, $SvcId, $SapPortId, $SapEncapValue) = ($1, $2, $3, $4);
        my $instance = $SysSwitchId . '.' . $SvcId . '.' . $SapPortId . '.' . $SapEncapValue;
        
        my $SapDescription = $snmp_result->{$oid_tnSapDescription}->{$oid};
        my $SvcName = defined($snmp_result->{$oid_tnSvcName}->{$oid_tnSvcName . '.' . $SysSwitchId . '.' . $SvcId}) ?
           $snmp_result->{$oid_tnSvcName}->{$oid_tnSvcName . '.' . $SysSwitchId . '.' . $SvcId} : '';
        
        my $name = $self->get_display_name(SapDescription => $SapDescription, SvcName => $SvcName, SysSwitchId => $SysSwitchId, SvcId => $SvcId, SapPortId => $SapPortId, SapEncapValue => $SapEncapValue);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{sap}->{$instance} = { display => $name };
    }
    
    $options{snmp}->load(oids => [$mapping->{tnSapBaseStatsIngressForwardedOctets}->{oid}, 
        $mapping->{tnSapBaseStatsEgressForwardedOctets}->{oid}, $mapping->{tnSapBaseStatsIngressDroppedPackets}->{oid},
        $mapping->{tnSapAdminStatus}->{oid}, $mapping->{tnSapOperStatus}->{oid}], 
        instances => [keys %{$self->{sap}}], instance_regexp => '(\d+\.\d+\.\d+\.\d+)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    foreach (keys %{$self->{sap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
        $self->{sap}->{$_}->{in} = $result->{tnSapBaseStatsIngressForwardedOctets} * 8;
        $self->{sap}->{$_}->{out} = $result->{tnSapBaseStatsEgressForwardedOctets} * 8;
        $self->{sap}->{$_}->{in_dropped_packets} = $result->{tnSapBaseStatsIngressDroppedPackets};
        $self->{sap}->{$_}->{status} = $result->{tnSapAdminStatus};
        $self->{sap}->{$_}->{admin} = $result->{tnSapOperStatus};
    }

    if (scalar(keys %{$self->{sap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No SAP found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "alcatel_pss_1830_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check SAP QoS usage.

=over 8

=item B<--display-name>

Display name (Default: '%{SysSwitchId}.%{SvcId}.%{SapPortId}.%{SapEncapValue}').
Can also be: %{SapDescription}, %{SvcName}

=item B<--filter-name>

Filter by SAP name (can be a regexp).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--warning-status>

Set warning threshold for ib status.
Can used special variables like: %{admin}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for ib status (Default: '%{admin} =~ /up/i and %{status} !~ /up/i').
Can used special variables like: %{admin}, %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'in-traffic', 'out-traffic', 'in-drop-packets'.

=item B<--critical-*>

Threshold critical.
Can be: 'in-traffic', 'out-traffic', 'in-drop-packets'.

=back

=cut
