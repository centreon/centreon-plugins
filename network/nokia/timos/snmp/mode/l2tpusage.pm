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

package network::nokia::timos::snmp::mode::l2tpusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Socket;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'state : ' . $self->{result_values}->{state};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}


sub custom_total_sessions_calc {
    my ($self, %options) = @_;

    my $total_sessions = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_total_sessions_(\d+)/) {
            my $new_total = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_total = $options{old_datas}->{$_};
            
            my $diff_sessions = $new_total - $old_total;
            if ($diff_sessions < 0) {
                $total_sessions += $old_total;
            } else {
                $total_sessions += $diff_sessions;
            }
        }
    }
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total_sessions} = $total_sessions;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'tunnel', type => 1, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All tunnels are ok' },
        { name => 'vrtr', type => 1, cb_prefix_output => 'prefix_vrtr_output', message_multiple => 'All tunnels by virtual router are ok' },
        { name => 'peer', type => 1, cb_prefix_output => 'prefix_peer_output', message_multiple => 'All tunnels by peer router are ok' },
    ];
    $self->{maps_counters}->{tunnel} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    
    $self->{maps_counters}->{vrtr} = [
        { label => 'vrtr-tunnel-total', set => {
                key_values => [ { name => 'total_tunnel' }, { name => 'display' } ],
                output_template => 'Total : %s',
                perfdatas => [
                    { label => 'vrtr_total_tunnel', value => 'total_tunnel', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'vrtr-tunnel-active-sessions', set => {
                key_values => [ { name => 'active_sessions' }, { name => 'display' } ],
                output_template => 'Active Sessions : %s',
                perfdatas => [
                    { label => 'vrtr_tunnel_active_sessions', value => 'active_sessions', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'vrtr-tunnel-total-sessions', set => {
                key_values => [],
                manual_keys => 1,
                output_template => 'Total Sessions : %s',
                threshold_use => 'total_sessions', output_use => 'total_sessions',
                closure_custom_calc => $self->can('custom_total_sessions_calc'),
                perfdatas => [
                    { label => 'vrtr_tunnel_total_sessions', value => 'total_sessions', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{peer} = [
        { label => 'peer-tunnel-total', set => {
                key_values => [ { name => 'total_tunnel' }, { name => 'display' } ],
                output_template => 'Total : %s',
                perfdatas => [
                    { label => 'peer_total_tunnel', value => 'total_tunnel', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'peer-tunnel-active-sessions', set => {
                key_values => [ { name => 'active_sessions' }, { name => 'display' } ],
                output_template => 'Active Sessions : %s',
                perfdatas => [
                    { label => 'peer_tunnel_active_sessions', value => 'active_sessions', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'peer-tunnel-total-sessions', set => {
                key_values => [],
                manual_keys => 1,
                output_template => 'Total Sessions : %s',
                threshold_use => 'total_sessions', output_use => 'total_sessions',
                closure_custom_calc => $self->can('custom_total_sessions_calc'),
                perfdatas => [
                    { label => 'peer_tunnel_total_sessions', value => 'total_sessions', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;
    
    return "Tunnel '" . $options{instance_value}->{display} . "' ";
}

sub prefix_vrtr_output {
    my ($self, %options) = @_;
    
    return "Virtual router '" . $options{instance_value}->{display} . "' Tunnel ";
}

sub prefix_peer_output {
    my ($self, %options) = @_;
    
    return "Peer '" . $options{instance_value}->{display} . "' Tunnel ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-vrtr-name:s"      => { name => 'filter_vrtr_name' },
                                  "filter-peer-addr:s"      => { name => 'filter_peer_addr' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (1 => 'unknown', 2 => 'idle', 3 => 'waitReply', 4 => 'waitConn',
    5 => 'establishedIdle', 6 => 'established', 7 => 'draining', 8 => 'drained',
    9 => 'closed', 10 => 'closedByPeer'
);

my $oid_vRtrName = '.1.3.6.1.4.1.6527.3.1.2.3.1.1.4';
# index vRtrID and TuStatusId
my $mapping = {
    tmnxL2tpTuStatusState           => { oid => '.1.3.6.1.4.1.6527.3.1.2.60.1.3.2.2.1.2', map => \%map_status },
    tmnxL2tpTuStatusPeerAddr        => { oid => '.1.3.6.1.4.1.6527.3.1.2.60.1.3.2.2.1.6' },
    tmnxL2tpTuStatsTotalSessions    => { oid => '.1.3.6.1.4.1.6527.3.1.2.60.1.3.2.3.1.2' },
    tmnxL2tpTuStatsActiveSessions   => { oid => '.1.3.6.1.4.1.6527.3.1.2.60.1.3.2.3.1.4' },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vRtrName },
                                                            { oid => $mapping->{tmnxL2tpTuStatusPeerAddr}->{oid} },
                                                            { oid => $mapping->{tmnxL2tpTuStatusState}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{vrtr} = {};
    $self->{peer} = {};
    $self->{tunnel} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{tmnxL2tpTuStatusState}->{oid}\.(.*?)\.(.*)$/);
        my ($vrtr_id, $l2tp_tu_id) = ($1, $2);
        
        my $vrtr_name = $snmp_result->{$oid_vRtrName . '.' . $vrtr_id};
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $vrtr_id . '.' . $l2tp_tu_id);
        my $peer_addr = inet_ntoa($result->{tmnxL2tpTuStatusPeerAddr});
        if (defined($self->{option_results}->{filter_vrtr_name}) && $self->{option_results}->{filter_vrtr_name} ne '' &&
            $vrtr_name !~ /$self->{option_results}->{filter_vrtr_name}/) {
            $self->{output}->output_add(long_msg => "skipping vrtr '" . $vrtr_name . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_peer_addr}) && $self->{option_results}->{filter_peer_addr} ne '' &&
            $peer_addr !~ /$self->{option_results}->{filter_peer_addr}/) {
            $self->{output}->output_add(long_msg => "skipping peer addr '" . $peer_addr . "'.", debug => 1);
            next;
        }
        
        $self->{tunnel}->{$vrtr_id . '.' . $l2tp_tu_id} = { display => $vrtr_name . '-' . $peer_addr, state => $result->{tmnxL2tpTuStatusState} };
        $self->{vrtr}->{$vrtr_name} = { display => $vrtr_name, total_tunnel => 0, active_sessions => 0 } if (!defined($self->{vrtr}->{$vrtr_name}));
        $self->{vrtr}->{$vrtr_name}->{total_tunnel}++;
        
        $self->{peer}->{$peer_addr} = { display => $peer_addr, total_tunnel => 0, active_sessions => 0 } if (!defined($self->{peer}->{$peer_addr}));
        $self->{peer}->{$peer_addr}->{total_tunnel}++;
    }
    
    $options{snmp}->load(oids => [$mapping->{tmnxL2tpTuStatsActiveSessions}->{oid}, $mapping->{tmnxL2tpTuStatsTotalSessions}->{oid}], 
        instances => [keys %{$self->{tunnel}}], instance_regexp => '^(.*)$');
    my $snmp_result2 = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{tunnel}}) {
        /(\d+)\.\d+/;
        my $vrtr_name = $snmp_result->{$oid_vRtrName . '.' . $1};
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => { %$snmp_result, %$snmp_result2 }, instance => $_);  
        my $peer_addr = inet_ntoa($result->{tmnxL2tpTuStatusPeerAddr});
        
        $self->{vrtr}->{$vrtr_name}->{active_sessions} += $result->{tmnxL2tpTuStatsActiveSessions};
        $self->{peer}->{$peer_addr}->{active_sessions} += $result->{tmnxL2tpTuStatsActiveSessions};
        $self->{vrtr}->{$vrtr_name}->{'total_sessions_' . $_} = $result->{tmnxL2tpTuStatsTotalSessions};
        $self->{peer}->{$peer_addr}->{'total_sessions_' . $_} = $result->{tmnxL2tpTuStatsTotalSessions};
    }
    
    if (scalar(keys %{$self->{tunnel}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No tunnel found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "nokia_timos_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_vrtr_name}) ? md5_hex($self->{option_results}->{filter_vrtr_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_peer_addr}) ? md5_hex($self->{option_results}->{filter_peer_addr}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check L2TP usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'vrtr-tunnel-total', 'vrtr-tunnel-active-sessions', 'vrtr-tunnel-total-sessions', 
'peer-tunnel-total', 'peer-tunnel-active-sessions', 'peer-tunnel-total-sessions'.

=item B<--critical-*>

Threshold critical.
Can be: 'vrtr-tunnel-total', 'vrtr-tunnel-active-sessions', 'vrtr-tunnel-total-sessions', 
'peer-tunnel-total', 'peer-tunnel-active-sessions', 'peer-tunnel-total-sessions'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{state}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like:  %{display}, %{state}

=item B<--filter-vrtr-name>

Filter by vrtr name (can be a regexp).

=item B<--filter-peer-addr>

Filter by peer addr (can be a regexp).

=back

=cut
