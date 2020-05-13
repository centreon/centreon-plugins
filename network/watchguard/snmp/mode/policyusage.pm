#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::watchguard::snmp::mode::policyusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'policy', type => 1, cb_prefix_output => 'prefix_policy_output', message_multiple => 'All policies are ok' }
    ];
    
    $self->{maps_counters}->{policy} = [
        { label => 'current-connections', set => {
                key_values => [ { name => 'wgPolicyCurrActiveConns' }, { name => 'display' } ],
                output_template => 'Current connections : %s',
                perfdatas => [
                    { label => 'current_connections', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-connections', set => {
                key_values => [ { name => 'wgPolicyActiveStreams', diff => 1 }, { name => 'display' } ],
                output_template => 'Total connections : %s',
                perfdatas => [
                    { label => 'total_connections', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'l3-traffic', set => {
                key_values => [ { name => 'wgPolicyL3PackageBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'L3 Traffic : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_l3', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'l2-traffic', set => {
                key_values => [ { name => 'wgPolicyL2PackageBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'L2 Traffic : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_l2', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub prefix_policy_output {
    my ($self, %options) = @_;
    
    return "Policy '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    wgPolicyName            => { oid => '.1.3.6.1.4.1.3097.4.2.2.1.2' },
    wgPolicyL3PackageBytes  => { oid => '.1.3.6.1.4.1.3097.4.2.2.1.3' },
    wgPolicyActiveStreams   => { oid => '.1.3.6.1.4.1.3097.4.2.2.1.12' },
    wgPolicyCurrActiveConns => { oid => '.1.3.6.1.4.1.3097.4.2.2.1.18' },
    wgPolicyL2PackageBytes  => { oid => '.1.3.6.1.4.1.3097.4.2.2.1.19' },
};

my $oid_wgPolicyEntry = '.1.3.6.1.4.1.3097.4.2.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{policy} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_wgPolicyEntry,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{wgPolicyName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{wgPolicyName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wgPolicyName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{policy}->{$instance} = { display => $result->{wgPolicyName}, 
            %$result
        };
    }
    
    if (scalar(keys %{$self->{policy}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No policy found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "watchguard_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check policy usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-connections$'

=item B<--filter-name>

Filter policy name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'total-connections', 'current-connections'
'l3-traffic' (b/s), 'l2-traffic' (b/s).

=item B<--critical-*>

Threshold critical.
Can be: 'total-connections', 'current-connections'
'l3-traffic' (b/s), 'l2-traffic' (b/s).

=back

=cut
