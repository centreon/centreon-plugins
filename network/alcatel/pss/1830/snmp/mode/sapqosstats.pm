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

package network::alcatel::pss::1830::snmp::mode::sapqosstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sap', type => 1, cb_prefix_output => 'prefix_sap_output', message_multiple => 'All SAP QoS are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{sap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'tnSapOperStatus' }, { name => 'tnSapAdminStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'traffic-in-below-cir', set => {
                key_values => [ { name => 'tnSapBaseStatsIngressQchipForwardedInProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In Below CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in_below_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in-above-cir', set => {
                key_values => [ { name => 'tnSapBaseStatsIngressQchipForwardedOutProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In Above CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in_above_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out-below-cir', set => {
                key_values => [ { name => 'tnSapBaseStatsEgressQchipForwardedInProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out Below CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out_below_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out-above-cir', set => {
                key_values => [ { name => 'tnSapBaseStatsEgressQchipForwardedOutProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out Above CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out_above_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ' . $self->{result_values}->{status} . ' (admin: ' . $self->{result_values}->{admin} . ')';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{admin} = $options{new_datas}->{$self->{instance} . '_tnSapAdminStatus'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_tnSapOperStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'reload-cache-time:s' => { name => 'reload_cache_time', default => 300 },
        'display-name:s'      => { name => 'display_name', default => '%{SysSwitchId}.%{SvcId}.%{SapPortId}.%{SapEncapValue}' },
        'filter-name:s'       => { name => 'filter_name' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{admin} =~ /up/i and %{status} !~ /up/i' }
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
    tnSapAdminStatus    => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.2.1.6', map => \%map_admin },
    tnSapOperStatus     => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.2.1.7', map => \%map_oper },
    tnSapBaseStatsIngressQchipForwardedInProfOctets     => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.6.1.12' },
    tnSapBaseStatsIngressQchipForwardedOutProfOctets    => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.6.1.14' },
    tnSapBaseStatsEgressQchipForwardedInProfOctets      => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.6.1.20' },
    tnSapBaseStatsEgressQchipForwardedOutProfOctets     => { oid => '.1.3.6.1.4.1.7483.6.1.2.4.3.6.1.22' },
};

my $oid_tnSapDescription = '.1.3.6.1.4.1.7483.6.1.2.4.3.2.1.5';
my $oid_tnSvcName = '.1.3.6.1.4.1.7483.6.1.2.4.2.2.1.28';

sub reload_cache {
    my ($self, %options) = @_;
    
    my $datas = { last_timestamp => time() };
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $oid_tnSapDescription }, 
            { oid => $oid_tnSvcName },
        ],
        nothing_quit => 1);
    $datas->{snmp_result} = $snmp_result;
   
    if (scalar(keys %{$datas->{snmp_result}->{$oid_tnSapDescription}}) <= 0) {
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

    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_alcatel_pss1830_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode});
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) ||
        ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $self->reload_cache(%options);
        $self->{statefile_cache}->read();
    }

    my $snmp_result = $self->{statefile_cache}->get(name => 'snmp_result');
    
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
    
    $options{snmp}->load(oids => [$mapping->{tnSapBaseStatsIngressQchipForwardedInProfOctets}->{oid}, 
        $mapping->{tnSapBaseStatsIngressQchipForwardedOutProfOctets}->{oid}, $mapping->{tnSapBaseStatsEgressQchipForwardedInProfOctets}->{oid},
        $mapping->{tnSapBaseStatsEgressQchipForwardedOutProfOctets}->{oid},
        $mapping->{tnSapAdminStatus}->{oid}, $mapping->{tnSapOperStatus}->{oid}], 
        instances => [keys %{$self->{sap}}], instance_regexp => '(\d+\.\d+\.\d+\.\d+)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    foreach (keys %{$self->{sap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
        
        foreach my $name (('tnSapBaseStatsIngressQchipForwardedInProfOctets', 'tnSapBaseStatsIngressQchipForwardedOutProfOctets',
                           'tnSapBaseStatsEgressQchipForwardedInProfOctets', 'tnSapBaseStatsEgressQchipForwardedOutProfOctets')) {
            $result->{$name} *= 8 if (defined($result->{$name}));
        }
        
        foreach my $name (keys %$mapping) {
            $self->{sap}->{$_}->{$name} = $result->{$name} if (defined($result->{$name}));
        }
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

=item B<--warning-status>

Set warning threshold for ib status.
Can used special variables like: %{admin}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for ib status (Default: '%{admin} =~ /up/i and %{status} !~ /up/i').
Can used special variables like: %{admin}, %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in-above-cir', 'traffic-in-below-cir', 'traffic-out-above-cir', 'traffic-out-below-cir'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in-above-cir', 'traffic-in-below-cir', 'traffic-out-above-cir', 'traffic-out-below-cir'.

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 300).

=back

=cut
