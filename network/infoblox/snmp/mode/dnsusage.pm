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

package network::infoblox::snmp::mode::dnsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'dns', type => 1, cb_prefix_output => 'prefix_dns_output', message_multiple => 'All dns zones are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-query-rate', set => {
                key_values => [ { name => 'ibDnsQueryRate' } ],
                output_template => 'Total query rate : %s',
                perfdatas => [
                    { label => 'total_query_rate', value => 'ibDnsQueryRate', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-hit-ratio', set => {
                key_values => [ { name => 'ibDnsHitRatio' } ],
                output_template => 'Total hit ratio : %.2f %%',
                perfdatas => [
                    { label => 'total_hit_ratio', value => 'ibDnsHitRatio', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{dns} = [
        { label => 'success-count', set => {
                key_values => [ { name => 'ibBindZoneSuccess', diff => 1 }, { name => 'display' } ],
                output_template => 'Success responses : %s',
                perfdatas => [
                    { label => 'success_count', value => 'ibBindZoneSuccess', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'referral-count', set => {
                key_values => [ { name => 'ibBindZoneReferral', diff => 1 }, { name => 'display' } ],
                output_template => 'Referrals : %s',
                perfdatas => [
                    { label => 'referral_count', value => 'ibBindZoneReferral', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'nxrrset-count', set => {
                key_values => [ { name => 'ibBindZoneNxRRset', diff => 1 }, { name => 'display' } ],
                output_template => 'Non-existent record : %s',
                perfdatas => [
                    { label => 'nxrrset_count', value => 'ibBindZoneNxRRset', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'failure-count', set => {
                key_values => [ { name => 'ibBindZoneFailure', diff => 1 }, { name => 'display' } ],
                output_template => 'Failed queries : %s',
                perfdatas => [
                    { label => 'failure_count', value => 'ibBindZoneFailure', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' },
    });
    
    return $self;
}

sub prefix_dns_output {
    my ($self, %options) = @_;
    
    return "Zone '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    ibBindZoneName      => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.1' },
    ibBindZoneSuccess   => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.2' },
    ibBindZoneReferral  => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.3' },
    ibBindZoneNxRRset   => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.4' },
    ibBindZoneFailure   => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.7' },
};
my $mapping2 = {
    ibDnsHitRatio       => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.5' },
    ibDnsQueryRate      => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.6' },
};

my $oid_ibZoneStatisticsEntry = '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1';
my $oid_ibDnsModule = '.1.3.6.1.4.1.7779.3.1.1.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{dns} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_ibZoneStatisticsEntry },
            { oid => $oid_ibDnsModule, start => $mapping2->{ibDnsHitRatio}->{oid} },
        ],
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result->{$oid_ibZoneStatisticsEntry}}) {
        next if ($oid !~ /^$mapping->{ibBindZoneName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_ibZoneStatisticsEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ibBindZoneName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ibBindZoneName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{dns}->{$instance} = { display => $result->{ibBindZoneName}, 
            %$result
        };
    }
    
    if (scalar(keys %{$self->{dns}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No dns zone found.");
        $self->{output}->option_exit();
    }
    
    my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_ibDnsModule}, instance => '0');
    $self->{global} = { %$result };
    
    $self->{cache_name} = "infoblox_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check dns usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^success-coun$'

=item B<--filter-name>

Filter dns zone name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'total-query-rate', 'total-hit-ratio', 'success-count', 'referral-count', 'nxrrset-count', 
'failure-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-query-rate', 'total-hit-ratio', 'success-count', 'referral-count', 'nxrrset-count', 
'failure-count'.

=back

=cut
