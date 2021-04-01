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

package network::nokia::timos::snmp::mode::ldpusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'IPv4 state : ' . $self->{result_values}->{ipv4_oper_state} . ' (admin: ' . $self->{result_values}->{admin_state} . ')';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ipv4_oper_state} = $options{new_datas}->{$self->{instance} . '_ipv4_oper_state'};
    $self->{result_values}->{admin_state} = $options{new_datas}->{$self->{instance} . '_admin_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ldp', type => 1, cb_prefix_output => 'prefix_ldp_output', message_multiple => 'All ldp instances are ok' }
    ];
    
    $self->{maps_counters}->{ldp} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'ipv4_oper_state' }, { name => 'admin_state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'ipv4-active-sessions', set => {
                key_values => [ { name => 'ipv4_active_sessions' }, { name => 'display' } ],
                output_template => 'IPv4 Active Sessions : %s',
                perfdatas => [
                    { label => 'ipv4_active_sessions', value => 'ipv4_active_sessions', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'ipv4-active-link-adj', set => {
                key_values => [ { name => 'ipv4_active_link_adj' }, { name => 'display' } ],
                output_template => 'IPv4 Active Link Adjacencies : %s',
                perfdatas => [
                    { label => 'ipv4_active_link_adj', value => 'ipv4_active_link_adj', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'ipv4-active-target-adj', set => {
                key_values => [ { name => 'ipv4_active_target_adj' }, { name => 'display' } ],
                output_template => 'IPv4 Active Target Adjacencies : %s',
                perfdatas => [
                    { label => 'ipv4_active_target_adj', value => 'ipv4_active_target_adj', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'ipv4-oper-down-events', set => {
                key_values => [ { name => 'ipv4_oper_down_events', diff => 1 }, { name => 'display' } ],
                output_template => 'IPv4 Oper Down Events : %s',
                perfdatas => [
                    { label => 'ipv4_oper_down_events', value => 'ipv4_oper_down_events', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_ldp_output {
    my ($self, %options) = @_;
    
    return "LDP instance '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{admin_state} eq "inService" and %{ipv4_oper_state} !~ /inService|transition/' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_oper_state = (1 => 'unknown', 2 => 'inService', 3 => 'outOfService', 4 => 'transition');
my %map_admin_state = (1 => 'noop', 2 => 'inService', 3 => 'outOfService');

# index vRtrID
my $mapping = {
    vRtrName                    => { oid => '.1.3.6.1.4.1.6527.3.1.2.3.1.1.4' },
    vRtrLdpNgGenAdminState      => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.47.1.5', map => \%map_admin_state },
    vRtrLdpNgGenIPv4OperState   => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.47.1.6', map => \%map_oper_state },
};
# index vRtrID
my $mapping2 = {
    vLdpNgStatsIPv4OperDownEvents   => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.42.1.1' },
    vLdpNgStatsIPv4ActiveSess       => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.42.1.3' },
    vLdpNgStatsIPv4ActiveLinkAdj    => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.42.1.5' },
    vLdpNgStatsIPv4ActiveTargAdj    => { oid => '.1.3.6.1.4.1.6527.3.1.2.91.42.1.7' },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{vRtrName}->{oid} },
                                                            { oid => $mapping->{vRtrLdpNgGenAdminState}->{oid} },
                                                            { oid => $mapping->{vRtrLdpNgGenIPv4OperState}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{ldp} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vRtrLdpNgGenAdminState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (!defined($result->{vRtrName}) || $result->{vRtrName} eq '') {
            $self->{output}->output_add(long_msg => "skipping LDP '$instance': cannot get a name. please set it.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vRtrName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping LDP '" . $result->{vRtrName} . "'.", debug => 1);
            next;
        }
        
        $self->{ldp}->{$instance} = { display => $result->{vRtrName}, 
            admin_state => $result->{vRtrLdpNgGenAdminState},
            ipv4_oper_state => $result->{vRtrLdpNgGenIPv4OperState},
        };
    }
    
    $options{snmp}->load(oids => [$mapping2->{vLdpNgStatsIPv4OperDownEvents}->{oid}, $mapping2->{vLdpNgStatsIPv4ActiveSess}->{oid},
        $mapping2->{vLdpNgStatsIPv4ActiveLinkAdj}->{oid}, $mapping2->{vLdpNgStatsIPv4ActiveTargAdj}->{oid},
        ], 
        instances => [keys %{$self->{ldp}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{ldp}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);        
        
        $self->{ldp}->{$_}->{ipv4_oper_down_events} = $result->{vLdpNgStatsIPv4OperDownEvents};
        $self->{ldp}->{$_}->{ipv4_active_sessions} = $result->{vLdpNgStatsIPv4ActiveSess};
        $self->{ldp}->{$_}->{ipv4_active_link_adj} = $result->{vLdpNgStatsIPv4ActiveLinkAdj};
        $self->{ldp}->{$_}->{ipv4_active_target_adj} = $result->{vLdpNgStatsIPv4ActiveTargAdj};
    }
    
    if (scalar(keys %{$self->{ldp}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No LDP instance found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "nokia_timos_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check LDP usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'ipv4-oper-down-events', 'ipv4-active-sessions', 'ipv4-active-link-adj',
'ipv4-active-target-adj'.

=item B<--critical-*>

Threshold critical.
Can be: 'ipv4-oper-down-events', 'ipv4-active-sessions', 'ipv4-active-link-adj',
'ipv4-active-target-adj'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{ipv4_oper_state}, %{admin_state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admin_state} eq "inService" and %{ipv4_oper_state} !~ /inService|transition/').
Can used special variables like: %{ipv4_oper_state}, %{admin_state}, %{display}

=item B<--filter-name>

Filter by LDP instance name (can be a regexp).

=back

=cut
