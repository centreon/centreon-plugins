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

package network::juniper::common::screenos::snmp::mode::vpnstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "Phase 1 state is '" . $self->{result_values}->{p1state} . "', Phase 2 state is '" . $self->{result_values}->{p2state};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{p1state} = $options{new_datas}->{$self->{instance} . '_p1state'};
    $self->{result_values}->{p2state} = $options{new_datas}->{$self->{instance} . '_p2state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_update_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Update time: %s",
                        $self->{result_values}->{update_time} != 0 ? centreon::plugins::misc::change_seconds(value => $self->{result_values}->{update_time}) : 0);
    return $msg;
}

sub prefix_vpn_output {
    my ($self, %options) = @_;
    
    return "VPN '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPN are ok' }
    ];
    
    $self->{maps_counters}->{vpn} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'p1state' }, { name => 'p2state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'update-time', set => {
                key_values => [ { name => 'update_time'}, { name => 'display' } ],
                closure_custom_output => $self->can('custom_update_output'),
                perfdatas => [
                    { label => 'update_time', value => 'update_time', template => '%d',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{p1state} eq "inactive" || %{p2state} eq "inactive"' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_state = (0 => 'inactive', 1 => 'active');

my $mapping = {
    nsVpnMonVpnName     => { oid => '.1.3.6.1.4.1.3224.4.1.1.1.4' },
    nsVpnMonP1State     => { oid => '.1.3.6.1.4.1.3224.4.1.1.1.21', map => \%map_state },
    nsVpnMonP2State     => { oid => '.1.3.6.1.4.1.3224.4.1.1.1.23', map => \%map_state },
    nsVpnMonUpdateTime  => { oid => '.1.3.6.1.4.1.3224.4.1.1.1.40' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vpn} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $mapping->{nsVpnMonVpnName}->{oid} },
            { oid => $mapping->{nsVpnMonP1State}->{oid} },
            { oid => $mapping->{nsVpnMonP2State}->{oid} },
            { oid => $mapping->{nsVpnMonUpdateTime}->{oid} },
        ], nothing_quit => 1, return_type => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{nsVpnMonVpnName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{nsVpnMonVpnName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{nsVpnMonVpnName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vpn}->{$instance} = { display => $result->{nsVpnMonVpnName}, 
                                      p1state => $result->{nsVpnMonP1State},
                                      p2state => $result->{nsVpnMonP2State},
                                      update_time => $result->{nsVpnMonUpdateTime} / 100 };
    }
    
    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vpn found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Juniper VPN status (NETSCREEN-VPN-MON-MIB).

=over 8

=item B<--filter-name>

Filter VPN name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{p1state}, %{p2state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{p1state} eq "inactive" || %{p2state} eq "inactive"').
Can used special variables like: %{p1state}, %{p2state}

=item B<--warning-update-time>

Threshold warning for update time (in secondes).

=item B<--critical-update-time>

Threshold critical for update time (in secondes).

=back

=cut
