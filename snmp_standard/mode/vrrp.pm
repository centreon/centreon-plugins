#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::vrrp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("state : %s [admin state : '%s']", 
        $self->{result_values}->{operState}, $self->{result_values}->{adminState});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{adminState} = $options{new_datas}->{$self->{instance} . '_admin_state'};
    $self->{result_values}->{operStateLast} = $options{old_datas}->{$self->{instance} . '_oper_state'};
    $self->{result_values}->{operState} = $options{new_datas}->{$self->{instance} . '_oper_state'};
    $self->{result_values}->{masterIpAddr} = $options{new_datas}->{$self->{instance} . '_master_ip_addr'};
    if (!defined($options{old_datas}->{$self->{instance} . '_oper_state'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vrrp', type => 1, cb_prefix_output => 'prefix_vrrp_output', message_multiple => 'All VRRP are ok' },
    ];
    
    $self->{maps_counters}->{vrrp} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'master_ip_addr' }, { name => 'admin_state' }, { name => 'oper_state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_vrrp_output {
    my ($self, %options) = @_;

    return "VRRP '" . $options{instance_value}->{master_ip_addr} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "use-keepalived-mib"      => { name => 'use_keepalived_mib' },
                                "warning-status:s"        => { name => 'warning_status', default => '' },
                                "critical-status:s"       => { name => 'critical_status', default => '%{adminState} eq "up" and %{operState} ne %{operStateLast}' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    my %map_oper_state = (1 => 'initialize', 2 => 'backup', 3 => 'master');
    my %map_admin_state = (1 => 'up', 2 => 'down');
    $self->{mapping} = {
        vrrpOperState           => { oid => '.1.3.6.1.2.1.68.1.3.1.3', map => \%map_oper_state },
        vrrpOperAdminState      => { oid => '.1.3.6.1.2.1.68.1.3.1.4', map => \%map_admin_state },
        vrrpOperMasterIpAddr    => { oid => '.1.3.6.1.2.1.68.1.3.1.7' },
    };
    $self->{oid_vrrpOperEntry} = '.1.3.6.1.2.1.68.1.3.1';

    if (defined($self->{option_results}->{use_keepalived_mib})) {
        %map_oper_state = (0 => 'init', 1 => 'backup', 2 => 'master', 3 => 'fault', 4 => 'unknown');
        %map_admin_state = (0 => 'init', 1 => 'backup', 2 => 'master', 3 => 'fault', 4 => 'unknown');
        $self->{mapping} = {
            vrrpOperState           => { oid => '.1.3.6.1.4.1.9586.100.5.2.3.1.4', map => \%map_oper_state },
            vrrpOperAdminState      => { oid => '.1.3.6.1.4.1.9586.100.5.2.3.1.6', map => \%map_admin_state },
            vrrpOperMasterIpAddr    => { oid => '.1.3.6.1.4.1.9586.100.5.2.3.1.10' },
        };
        $self->{oid_vrrpOperEntry} = '.1.3.6.1.4.1.9586.100.5.2.3.1';
        if ($self->{option_results}->{critical_status} eq '%{adminState} eq "up" and %{operState} ne %{operStateLast}') {
            $self->{option_results}->{critical_status} = '%{operState} ne %{adminState} or %{operState} ne %{operStateLast}';
        }
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vrrp} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $self->{oid_vrrpOperEntry}, end => $self->{mapping}->{vrrpOperMasterIpAddr}->{oid},
                                                nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$self->{mapping}->{vrrpOperState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $self->{mapping}, results => $snmp_result, instance => $instance);
        
        $self->{vrrp}->{$instance} = { 
            master_ip_addr => $result->{vrrpOperMasterIpAddr},
            admin_state => $result->{vrrpOperAdminState},
            oper_state => $result->{vrrpOperState},
        };
    }
    
    $self->{cache_name} = "vrrp_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check VRRP status (VRRP-MIB).

=over 8

=item B<--use-keepalived-mib>

Some devices do not (fully) support VRRP MIB, use KEEPALIVED MIB instead.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{adminState}, %{operStateLast}, %{operState}, %{masterIpAddr}

=item B<--critical-status>

Set critical threshold for status (Default: '%{adminState} eq "up" and %{operState} ne %{operStateLast}',
with --use-keepalived-mib: '%{operState} ne %{adminState} or %{operState} ne %{operStateLast}').
Can used special variables like: %{adminState}, %{operStateLast}, %{operState}, %{masterIpAddr}

=back

=cut
    
