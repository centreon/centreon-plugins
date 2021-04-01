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

package network::nokia::timos::snmp::mode::bgpusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bgp', type => 1, cb_prefix_output => 'prefix_bgp_output', message_multiple => 'All BGP are ok' },
    ];
    $self->{maps_counters}->{bgp} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'active-prefixes', set => {
                key_values => [ { name => 'active_prefixes' }, { name => 'display' } ],
                output_template => 'Active Prefixes : %s',
                perfdatas => [
                    { label => 'active_prefixes', value => 'active_prefixes', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'sent-prefixes', set => {
                key_values => [ { name => 'sent_prefixes', diff => 1 }, { name => 'display' } ],
                output_template => 'Sent Prefixes : %s',
                perfdatas => [
                    { label => 'sent_prefixes', value => 'sent_prefixes', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'received-prefixes', set => {
                key_values => [ { name => 'received_prefixes', diff => 1 }, { name => 'display' } ],
                output_template => 'Received Prefixes : %s',
                perfdatas => [
                    { label => 'received_prefixes', value => 'received_prefixes', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_bgp_output {
    my ($self, %options) = @_;
    
    return "BGP '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{state} =~ /outOfService/' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (1 => 'unknown', 2 => 'inService', 3 => 'outOfService',
    4 => 'transition', 5 => 'disabled',
);

my $oid_vRtrName = '.1.3.6.1.4.1.6527.3.1.2.3.1.1.4';
my $mapping = {
    tBgpPeerNgDescription           => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.7.1.7' },
    tBgpPeerNgOperStatus            => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.7.1.42', map => \%map_status },
    tBgpPeerNgPeerAS4Byte           => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.7.1.66' },
    tBgpPeerNgOperReceivedPrefixes  => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.8.1.5' },
    tBgpPeerNgOperSentPrefixes      => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.8.1.6' },
    tBgpPeerNgOperActivePrefixes    => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.8.1.7' },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vRtrName },
                                                            { oid => $mapping->{tBgpPeerNgDescription}->{oid} },
                                                            { oid => $mapping->{tBgpPeerNgPeerAS4Byte}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{bgp} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{tBgpPeerNgPeerAS4Byte}->{oid}\.(\d+)\.(\d+)\.(.*)$/);
        my ($vrtr_id, $peer_type, $peer_addr) = ($1, $2, $3);
        
        my $vrtr_name = $snmp_result->{$oid_vRtrName . '.' . $vrtr_id};
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $vrtr_id . '.' . $peer_type . '.' . $peer_addr);
        
        my $name = $vrtr_name . ':' . $peer_addr . ':' . $result->{tBgpPeerNgPeerAS4Byte} . ':' . $result->{tBgpPeerNgDescription};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "'.", debug => 1);
            next;
        }
        
        $self->{bgp}->{$vrtr_id . '.' . $peer_type . '.' . $peer_addr} = {
            display => $name
        };
    }
    
    $options{snmp}->load(oids => [$mapping->{tBgpPeerNgOperReceivedPrefixes}->{oid}, $mapping->{tBgpPeerNgOperSentPrefixes}->{oid},
        $mapping->{tBgpPeerNgOperActivePrefixes}->{oid}, $mapping->{tBgpPeerNgOperStatus}->{oid}], 
        instances => [keys %{$self->{bgp}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    foreach (keys %{$self->{bgp}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);  
        
        $self->{bgp}->{$_}->{sent_prefixes} = $result->{tBgpPeerNgOperSentPrefixes};
        $self->{bgp}->{$_}->{active_prefixes} = $result->{tBgpPeerNgOperActivePrefixes};
        $self->{bgp}->{$_}->{received_prefixes} = $result->{tBgpPeerNgOperReceivedPrefixes};
        $self->{bgp}->{$_}->{state} = $result->{tBgpPeerNgOperStatus};
    }
    
    if (scalar(keys %{$self->{bgp}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No bgp found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "nokia_timos_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check BGP usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'active-prefixes', 'sent-prefixes', 'received-prefixes'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-prefixes', 'sent-prefixes', 'received-prefixes'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /outOfService/')
Can used special variables like:  %{display}, %{state}

=item B<--filter-name>

Filter by BGP name (can be a regexp).
Syntax: VrtrName:peeraddr:peerAS:description

=back

=cut
