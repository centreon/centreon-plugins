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

package network::oracle::infiniband::snmp::mode::infinibandusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ib', type => 1, cb_prefix_output => 'prefix_ib_output', message_multiple => 'All infiniband interfaces are ok', cb_init => 'skip_empty_ib', skipped_code => { -10 => 1 } },
        { name => 'ibgw', type => 1, cb_prefix_output => 'prefix_ibgw_output', message_multiple => 'All gateway infiniband interfaces are ok', cb_init => 'skip_empty_ibgw', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{ib} = [
        { label => 'ib-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold')
            }
        },
        { label => 'in', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'display' }, { name => 'speed_in' } ],
                closure_custom_calc => $self->can('custom_ib_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_ib_output'),
                closure_custom_perfdata => $self->can('custom_ib_perfdata'),
                closure_custom_threshold_check => $self->can('custom_ib_threshold')
            }
        },
        { label => 'out', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'display' }, { name => 'speed_out' } ],
                closure_custom_calc => $self->can('custom_ib_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_ib_output'),
                closure_custom_perfdata => $self->can('custom_ib_perfdata'),
                closure_custom_threshold_check => $self->can('custom_ib_threshold')
            }
        }
    ];

    $self->{maps_counters}->{ibgw} = [
        { label => 'ibgw-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold')
            }
        },
        { label => 'in', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'display' }, { name => 'speed_in' } ],
                closure_custom_calc => $self->can('custom_ib_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_ib_output'),
                closure_custom_perfdata => $self->can('custom_ib_perfdata'),
                closure_custom_threshold_check => $self->can('custom_ib_threshold')
            }
        },
        { label => 'out', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'display' }, { name => 'speed_out' } ],
                closure_custom_calc => $self->can('custom_ib_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_ib_output'),
                closure_custom_perfdata => $self->can('custom_ib_perfdata'),
                closure_custom_threshold_check => $self->can('custom_ib_threshold')
            }
        }
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
        if (defined($self->{instance_mode}->{option_results}->{'critical_' . $label}) && $self->{instance_mode}->{option_results}->{'critical_' . $label} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{'critical_' . $label}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{'warning_' . $label}) && $self->{instance_mode}->{option_results}->{'warning_' . $label} ne '' &&
                 eval "$self->{instance_mode}->{option_results}->{'warning_' . $label}") {
            $status = 'warning';
        }

        $self->{instance_mode}->{last_status} = 0;
        if ($self->{result_values}->{status} ne 'down') {
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
    my $msg = 'Status : ' . $self->{result_values}->{status};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_ib_perfdata {
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
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $self->{result_values}->{speed}
    );
}

sub custom_ib_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_ib_output {
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

sub custom_ib_calc {
    my ($self, %options) = @_;
    
    return -10 if (defined($self->{instance_mode}->{last_status}) && $self->{instance_mode}->{last_status} == 0);
    
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_traffic = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}} - $options{old_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}};
    $self->{result_values}->{traffic} = $diff_traffic / $options{delta_time};    
    if ($options{new_datas}->{$self->{instance} . '_speed_' . $self->{result_values}->{label}} > 0) {
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $self->{result_values}->{label}} * 1000 * 1000;
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic} * 100 / $self->{result_values}->{speed};
    } elsif (defined($self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}}) && $self->{instance_mode}->{option_results}->{'speed_' . $self->{result_values}->{label}} =~ /[0-9]/) {
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
        'filter-ib-name:s'       => { name => 'filter_ib_name' },
        'filter-ibgw-name:s'     => { name => 'filter_ibgw_name' },
        'warning-ib-status:s'    => { name => 'warning_ib_status', default => '' },
        'critical-ib-status:s'   => { name => 'critical_ib_status', default => '%{status} !~ /active/i' },
        'warning-ibgw-status:s'  => { name => 'warning_ibgw_status', default => '' },
        'critical-ibgw-status:s' => { name => 'critical_ibgw_status', default => '%{status} !~ /up/i' },
        'speed-in:s'             => { name => 'speed_in' },
        'speed-out:s'            => { name => 'speed_out' },
        'units-traffic:s'        => { name => 'units_traffic', default => '%' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_ib_status', 'critical_ib_status', 'warning_ibgw_status', 'critical_ibgw_status']);
}

sub prefix_ib_output {
    my ($self, %options) = @_;
    
    return "Infiniband '" . $options{instance_value}->{display} . "' ";
}

sub prefix_ibgw_output {
    my ($self, %options) = @_;
    
    return "Infiniband gateway '" . $options{instance_value}->{display} . "' ";
}

sub skip_empty_ib {
    my ($self, %options) = @_;

    scalar(keys %{$self->{ib}}) > 0 ? return(0) : return(1);
}

sub skip_empty_ibgw {
    my ($self, %options) = @_;

    scalar(keys %{$self->{ibgw}}) > 0 ? return(0) : return(1);
}

my %map_link_state = (1 => 'down', 2 => 'init', 3 => 'armed', 4 => 'active', 5 => 'other');
my %map_gw_link_state = (0 => 'down', 1 => 'up');
my %map_link_speed = (
1 => 5000,  # sdr-2point5Gbps 
2 => 5000,  # ddr-5Gbps',
4 => 10000, # qdr-10Gbps
5 => '',    # other
);
my $mapping = {
    ibSmaPortLinkState          => { oid => '.1.3.6.1.4.1.42.2.135.2.2.5.1.1.6', map => \%map_link_state },
    ibSmaPortLinkSpeedActive    => { oid => '.1.3.6.1.4.1.42.2.135.2.2.5.1.1.10', map => \%map_link_speed },
};
my $mapping2 = {
    ibPmaPortXmitData           => { oid => '.1.3.6.1.4.1.42.2.135.2.6.1.2.1.3' },
    ibPmaPortRcvData            => { oid => '.1.3.6.1.4.1.42.2.135.2.6.1.2.1.4' },
    ibPmaExtPortConnector       => { oid => '.1.3.6.1.4.1.42.2.135.2.6.1.2.1.11' },
};
my $mapping3 = {
    gwPortLongName              => { oid => '.1.3.6.1.4.1.42.2.135.2.8.1.1.1.3' },
    gwPortLinkState             => { oid => '.1.3.6.1.4.1.42.2.135.2.8.1.1.1.5', map => \%map_gw_link_state },
};
my $mapping4 = {
    gwEthRxBytes                => { oid => '.1.3.6.1.4.1.42.2.135.2.8.1.2.1.4' },
    gwEthTxBytes                => { oid => '.1.3.6.1.4.1.42.2.135.2.8.1.2.1.13' },
};

my $oid_ibSmaPortInfoEntry = '.1.3.6.1.4.1.42.2.135.2.2.5.1.1';
my $oid_ibPmaExtPortCntrsEntry = '.1.3.6.1.4.1.42.2.135.2.6.1.2.1';
my $oid_gwPortStateEntry = '.1.3.6.1.4.1.42.2.135.2.8.1.1.1';
my $oid_gwEthPortCntrsEntry = '.1.3.6.1.4.1.42.2.135.2.8.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_ibSmaPortInfoEntry, end => $mapping->{ibSmaPortLinkSpeedActive}->{oid} },
                                                                   { oid => $oid_ibPmaExtPortCntrsEntry },
                                                                   { oid => $oid_gwPortStateEntry, end => $mapping3->{gwPortLinkState}->{oid} },
                                                                   { oid => $oid_gwEthPortCntrsEntry },
                                                                 ],
                                                         nothing_quit => 1);
    $self->{ib} = {};
    foreach my $oid (keys %{$snmp_result->{ $oid_ibSmaPortInfoEntry }}) {
        next if ($oid !~ /^$mapping->{ibSmaPortLinkState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{ $oid_ibSmaPortInfoEntry }, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{ $oid_ibPmaExtPortCntrsEntry }, instance => $instance);
        $result2->{ibPmaExtPortConnector} =~ s/\x00//g;
        if (defined($self->{option_results}->{filter_ib_name}) && $self->{option_results}->{filter_ib_name} ne '' &&
            $result2->{ibPmaExtPortConnector} !~ /$self->{option_results}->{filter_ib_name}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $result2->{ibPmaExtPortConnector} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ib}->{'ib_' . $instance} = { 
            display => $result2->{ibPmaExtPortConnector},
            status => $result->{ibSmaPortLinkState},
            in => $result2->{ibPmaPortRcvData} * 4 * 8, out => $result2->{ibPmaPortXmitData} * 4 * 8,
            speed_in => $result->{ibSmaPortLinkSpeedActive},
            speed_out => $result->{ibSmaPortLinkSpeedActive}};
    }
    
    $self->{ibgw} = {};
    foreach my $oid (keys %{$snmp_result->{ $oid_gwPortStateEntry }}) {
        next if ($oid !~ /^$mapping3->{gwPortLinkState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{ $oid_gwPortStateEntry }, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping4, results => $snmp_result->{ $oid_gwEthPortCntrsEntry }, instance => $instance);
        $result->{gwPortLongName} =~ s/\x00//g;
        if (defined($self->{option_results}->{filter_ibgw_name}) && $self->{option_results}->{filter_ibgw_name} ne '' &&
            $result->{gwPortLongName} !~ /$self->{option_results}->{filter_ibgw_name}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $result->{gwPortLongName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ibgw}->{'ibgw_' . $instance} = { 
            display => $result->{gwPortLongName},
            status => $result->{gwPortLinkState},
            in => $result2->{gwEthRxBytes} * 8, out => $result2->{gwEthTxBytes} * 8,
            speed_in => 10000,
            speed_out => 10000};
    }
    
    if (scalar(keys %{$self->{ibgw}}) <= 0 && scalar(keys %{$self->{ib}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interfaces found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "oracle_infiniband_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_ib_name}) ? md5_hex($self->{option_results}->{filter_ib_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_ibgw_name}) ? md5_hex($self->{option_results}->{filter_ibgw_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check infiniband interfaces usage.

=over 8

=item B<--filter-ib-name>

Filter by infiniband name (can be a regexp).

=item B<--filter-ibgw-name>

Filter by infiniband gateway name (can be a regexp).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--warning-ib-status>

Set warning threshold for ib status.
Can used special variables like: %{status}, %{display}

=item B<--critical-ib-status>

Set critical threshold for ib status (Default: '%{status} !~ /up/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'in', 'out'.

=item B<--critical-*>

Threshold critical.
Can be: 'in', 'out'.

=back

=cut
