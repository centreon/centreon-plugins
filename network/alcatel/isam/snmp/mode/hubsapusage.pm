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

package network::alcatel::isam::snmp::mode::hubsapusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sap', type => 1, cb_prefix_output => 'prefix_sap_output', message_multiple => 'All SAP are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{sap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'admin' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold')
            }
        },
        { label => 'in-traffic', nlabel => 'sap.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_sap_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_sap_output'),
                closure_custom_perfdata => $self->can('custom_sap_perfdata'),
                closure_custom_threshold_check => $self->can('custom_qsap_threshold')
            }
        },
        { label => 'out-traffic', nlabel => 'sap.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_sap_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_sap_output'),
                closure_custom_perfdata => $self->can('custom_sap_perfdata'),
                closure_custom_threshold_check => $self->can('custom_sap_threshold')
            }
        },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-in-traffic', nlabel => 'sap.traffic.in.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_total_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_total_traffic_output'),
                closure_custom_perfdata => $self->can('custom_total_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_total_traffic_threshold')
            }
        },
        { label => 'total-out-traffic', nlabel => 'sap.traffic.out.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_total_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_total_traffic_output'),
                closure_custom_perfdata => $self->can('custom_total_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_total_traffic_threshold')
            }
        },
    ];
}

sub custom_total_traffic_perfdata {
    my ($self, %options) = @_;
    
    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }
    
    $self->{output}->perfdata_add(
        label => 'total_traffic_' . $self->{result_values}->{label}, unit => 'b/s',
        nlabel => $self->{nlabel},
        value => sprintf("%.2f", $self->{result_values}->{total_traffic}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $self->{result_values}->{speed}
    );
}

sub custom_total_traffic_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{total_traffic}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_total_traffic_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_traffic}, network => 1);
    my ($total_value, $total_unit);
    if (defined($self->{result_values}->{speed}) && $self->{result_values}->{speed} =~ /[0-9]/) {
        ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{speed}, network => 1);
    }
   
    my $msg = sprintf("Total Traffic %s : %s/s (%s on %s)",
                      ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-',
                      defined($total_value) ? $total_value . $total_unit : '-');
    return $msg;
}

sub custom_total_traffic_calc {
    my ($self, %options) = @_;

    my $total_traffic = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/^global_traffic_$options{extra_options}->{label_ref}_/) {
            my $new_total = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_total = $options{old_datas}->{$_};

            my $diff_traffic = $new_total - $old_total;
            if ($diff_traffic < 0) {
                $total_traffic += $old_total;
            } else {
                $total_traffic += $diff_traffic;
            }
        }
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{total_traffic} = $total_traffic / $options{delta_time};
    if (defined($self->{instance_mode}->{option_results}->{'speed_total_' . $self->{result_values}->{label}}) && $self->{instance_mode}->{option_results}->{'speed_total_' . $self->{result_values}->{label}} =~ /[0-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{total_traffic} * 100 / ($self->{instance_mode}->{option_results}->{'speed_total_' . $self->{result_values}->{label}} * 1000 * 1000);
        $self->{result_values}->{speed} = $self->{instance_mode}->{option_results}->{'speed_total_' . $self->{result_values}->{label}} * 1000 * 1000;
    }
    return 0;
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
        if (defined($self->{instance_mode}->{option_results}->{'critical_' . $label}) && $self->{instance_mode}->{option_results}->{'critical_' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'critical_' . $label}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{'warning_' . $label}) && $self->{instance_mode}->{option_results}->{'warning_' . $label} ne '' &&
                 eval "$self->{instance_mode}->{option_results}->{'warning_' . $label}") {
            $status = 'warning';
        }

        $self->{instance_mode}->{last_status} = 0;
        if ($self->{result_values}->{admin} eq 'up') {
            $self->{instance_mode}->{last_status} = 1;
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

sub custom_sap_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }
    
    $self->{output}->perfdata_add(
        label => 'traffic_' . $self->{result_values}->{label}, unit => 'b/s',
        nlabel => $self->{nlabel},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $self->{result_values}->{speed}
    );
}

sub custom_sap_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_sap_output {
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

sub custom_sap_calc {
    my ($self, %options) = @_;
    
    return -10 if (defined($self->{instance_mode}->{last_status}) && $self->{instance_mode}->{last_status} == 0);
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic} = ($options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}} - $options{old_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}}) / $options{delta_time};
    if (defined($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}}) && $self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} =~ /[0-9]/) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / ($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000);
        $self->{result_values}->{speed} = $self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} * 1000 * 1000;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'reload-cache-time:s' => { name => 'reload_cache_time', default => 300 },
        'display-name:s'      => { name => 'display_name', default => '%{SvcDescription}.%{IfName}.%{SapEncapName}' },
        'filter-name:s'       => { name => 'filter_name' },
        'speed-in:s'          => { name => 'speed_in' },
        'speed-out:s'         => { name => 'speed_out' },
        'speed-total-in:s'    => { name => 'speed_total_in' },
        'speed-total-out:s'   => { name => 'speed_total_out' },
        'units-traffic:s'     => { name => 'units_traffic', default => '%' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{admin} =~ /up/i and %{status} !~ /up/i' },
    });
    
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
    $self->{statefile_cache}->check_options(%options);
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
    sapAdminStatus              => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.6', map => \%map_admin },
    sapOperStatus               => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.7', map => \%map_oper },
    fadSapStatsIngressOctets    => { oid => '.1.3.6.1.4.1.637.61.1.85.17.2.2.1.2' },
    fadSapStatsEgressOctets     => { oid => '.1.3.6.1.4.1.637.61.1.85.17.2.2.1.4' },
};

my $oid_sapDescription = '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.5';
my $oid_svcDescription = '.1.3.6.1.4.1.6527.3.1.2.4.2.2.1.6';
my $oid_ifName  = '.1.3.6.1.2.1.31.1.1.1.1';

sub reload_cache {
    my ($self, %options) = @_;
    
    my $datas = { last_timestamp => time() };
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $oid_sapDescription }, 
            { oid => $oid_svcDescription },
            { oid => $oid_ifName },
        ],
        nothing_quit => 1);
    $datas->{snmp_result} = $snmp_result;
   
    if (scalar(keys %{$datas->{snmp_result}->{$oid_sapDescription}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    $self->{statefile_cache}->write(data => $datas);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_alcatel_isam_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) ||
        ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $self->reload_cache(%options);
        $self->{statefile_cache}->read();
    }

    my $snmp_result = $self->{statefile_cache}->get(name => 'snmp_result');

    $self->{global} = {};
    $self->{sap} = {};

    foreach my $oid (keys %{$snmp_result->{$oid_sapDescription}}) {
        next if ($oid !~ /^$oid_sapDescription\.(.*?)\.(.*?)\.(.*?)$/);
        # $SvcId and $SapEncapValue is the same. We use service table
        my ($SvcId, $SapPortId, $SapEncapValue) = ($1, $2, $3);
        my $instance = $SvcId . '.' . $SapPortId . '.' . $SapEncapValue;
        
        my $SapDescription = $snmp_result->{$oid_sapDescription}->{$oid} ne '' ?
            $snmp_result->{$oid_sapDescription}->{$oid} : 'unknown';
        my $SvcDescription = defined($snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SvcId}) && $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SvcId} ne '' ?
           $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SvcId} : $SvcId;
        my $IfName = defined($snmp_result->{$oid_ifName}->{$oid_ifName . '.' . $SapPortId}) && $snmp_result->{$oid_ifName}->{$oid_ifName . '.' . $SapPortId} ne '' ?
           $snmp_result->{$oid_ifName}->{$oid_ifName . '.' . $SapPortId} :  $SapPortId;
        my $SapEncapName = defined($snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SapEncapValue}) && $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SapEncapValue} ne '' ?
           $snmp_result->{$oid_svcDescription}->{$oid_svcDescription . '.' . $SapEncapValue} : $SapEncapValue;
        
        my $name = $self->get_display_name(
            SapDescription => $SapDescription, 
            SvcDescription => $SvcDescription,
            SapEncapName => $SapEncapName, 
            IfName => $IfName,
            SvcId => $SvcId, 
            SapPortId => $SapPortId, 
            SapEncapValue => $SapEncapValue);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{sap}->{$instance} = { display => $name };
    }
    
    $options{snmp}->load(oids => [$mapping->{fadSapStatsIngressOctets}->{oid}, 
        $mapping->{fadSapStatsEgressOctets}->{oid},
        $mapping->{sapAdminStatus}->{oid}, $mapping->{sapOperStatus}->{oid}], 
        instances => [keys %{$self->{sap}}], instance_regexp => '(\d+\.\d+\.\d+)$');
    
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{sap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
        $self->{sap}->{$_}->{in} = $result->{fadSapStatsIngressOctets} * 8;
        $self->{sap}->{$_}->{out} = $result->{fadSapStatsEgressOctets} * 8;
        $self->{sap}->{$_}->{status} = $result->{sapOperStatus};
        $self->{sap}->{$_}->{admin} = $result->{sapAdminStatus};
        
        $self->{global}->{'traffic_in_' . $_} = $result->{fadSapStatsIngressOctets} * 8;
        $self->{global}->{'traffic_out_' . $_} = $result->{fadSapStatsEgressOctets} * 8;
    }

    if (scalar(keys %{$self->{sap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No SAP found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "alcatel_isam_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check SAP QoS usage.

=over 8

=item B<--display-name>

Display name (Default: '%{SvcDescription}.%{IfName}.%{SapEncapName}').
Can also be: %{SapDescription}, %{SapPortId}

=item B<--filter-name>

Filter by SAP name (can be a regexp).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--speed-total-in>

Set interface speed for total incoming traffic (in Mb).

=item B<--speed-total-out>

Set interface speed for total outgoing traffic (in Mb).

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
Can be: 'total-in-traffic', 'total-out-traffic', 'in-traffic', 'out-traffic'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-in-traffic', 'total-out-traffic', 'in-traffic', 'out-traffic'.

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 300).

=back

=cut
