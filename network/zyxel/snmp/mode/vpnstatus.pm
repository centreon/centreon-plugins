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

package network::zyxel::snmp::mode::vpnstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'connection status : ' . $self->{result_values}->{connectstatus} . ' [activation status: ' . $self->{result_values}->{activestatus} . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{activestatus} = $options{new_datas}->{$self->{instance} . '_activestatus'};
    $self->{result_values}->{connectstatus} = $options{new_datas}->{$self->{instance} . '_connectstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPN tunnels are OK' },
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'status', threshold => 0,  set => {
                key_values => [ { name => 'activestatus' }, { name => 'connectstatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "VPN '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{connectstatus} eq "disconnected"' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_active_status = (0 => 'inactive', 1 => 'active');
my %map_connect_status = (0 => 'disconnected', 1 => 'connected');

my $mapping = {
    vpnStatusConnectionName => { oid => '.1.3.6.1.4.1.890.1.6.22.2.4.1.2' },
    vpnStatusActiveStatus   => { oid => '.1.3.6.1.4.1.890.1.6.22.2.4.1.5', map => \%map_active_status },
    vpnStatusConnectStatus  => { oid => '.1.3.6.1.4.1.890.1.6.22.2.4.1.6', map => \%map_connect_status },
};

my $mapping2 = {
    vpnSaMonitorConnectionName  => { oid => '.1.3.6.1.4.1.890.1.6.22.2.6.1.2' },
    vpnSaMonitorInBytes         => { oid => '.1.3.6.1.4.1.890.1.6.22.2.6.1.7' },
    vpnSaMonitorOutBytes        => { oid => '.1.3.6.1.4.1.890.1.6.22.2.6.1.9' },
};

my $oid_vpnStatusEntry = '.1.3.6.1.4.1.890.1.6.22.2.4.1';
my $oid_vpnSaMonitorEntry = '.1.3.6.1.4.1.890.1.6.22.2.6.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "zyxel_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

    $self->{vpn} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $oid_vpnStatusEntry },
            { oid => $oid_vpnSaMonitorEntry },
        ], nothing_quit => 1);

    foreach my $oid (sort keys %{$snmp_result->{$oid_vpnStatusEntry}}) {
        next if ($oid !~ /^$mapping->{vpnStatusConnectionName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_vpnStatusEntry}, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vpnStatusConnectionName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{vpnStatusConnectionName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vpn}->{$result->{vpnStatusConnectionName}} = {
            display => $result->{vpnStatusConnectionName},
            activestatus => $result->{vpnStatusActiveStatus},
            connectstatus => $result->{vpnStatusConnectStatus},
        };
    }
    
    foreach my $oid (sort keys %{$snmp_result->{$oid_vpnSaMonitorEntry}}) {
        next if ($oid !~ /^$mapping2->{vpnSaMonitorConnectionName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_vpnSaMonitorEntry}, instance => $instance);
        next if (!defined($self->{vpn}->{$result->{vpnSaMonitorConnectionName}}));
        
        $self->{vpn}->{$result->{vpnSaMonitorConnectionName}}->{traffic_in} = $result->{vpnSaMonitorInBytes} * 8;
        $self->{vpn}->{$result->{vpnSaMonitorConnectionName}}->{traffic_out} = $result->{vpnSaMonitorOutBytes} * 8;
    }
    
    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vpn found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check VPN state and traffic.

=over 8

=item B<--filter-name>

Filter vpn name with regexp.

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{activestatus}, %{connectstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{connectstatus} eq "disconnected"').
Can used special variables like: %{activestatus}, %{connectstatus}, %{display}

=back

=cut
