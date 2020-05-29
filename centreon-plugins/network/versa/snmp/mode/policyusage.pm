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

package network::versa::snmp::mode::policyusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'qospolicy', type => 1, cb_prefix_output => 'prefix_qospolicy_output', message_multiple => 'All QOS policies are ok' },
        { name => 'appqospolicy', type => 1, cb_prefix_output => 'prefix_appqospolicy_output', message_multiple => 'All Applications QOS policies are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{qospolicy} = [
        { label => 'qos-policy-hit-count', nlabel => 'qos.policy.hit.count', set => {
                key_values => [ { name => 'qosPolicyHitCount', per_minute => 1 }, { name => 'display' } ],
                output_template => 'hits: %s',
                perfdatas => [
                    { label => 'qos_hit_count', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'qos-policy-dropped-packets', nlabel => 'qos.policy.packets.dropped.count', set => {
                key_values => [ { name => 'qosPolicyDropPktCount', diff => 1 }, { name => 'display' } ],
                output_template => 'dropped packets: %s/min',
                perfdatas => [
                    { label => 'qos_dropped_packets', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'qos-policy-dropped-bytes', nlabel => 'appqos.policy.dropped.bytes', set => {
                key_values => [ { name => 'qosPolicyDropByteCount', diff => 1 }, { name => 'display' } ],
                output_template => 'dropped packets (volume): %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'qos_dropped_packets_bytes', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'qos-policy-forwarded-packets', nlabel => 'qos.policy.packets.forwarded.count', set => {
                key_values => [ { name => 'qosPolicyForwardPktCount', per_minute => 1 }, { name => 'display' } ],
                output_template => 'forwarded packets: %s/min',
                perfdatas => [
                    { label => 'qos_forwarded_packets', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'qos-policy-forwarded-bytes', nlabel => 'qos.policy.forwarded.bytes', set => {
                key_values => [ { name => 'qosPolicyForwardByteCount', diff => 1 }, { name => 'display' } ],
                output_template => 'forwarded packets (volume): %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'qos_forwarded_packets_bytes', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];

    $self->{maps_counters}->{appqospolicy} = [
        { label => 'appqos-policy-hit-count', nlabel => 'appqos.policy.hit.count', set => {
                key_values => [ { name => 'appQosPolicyHitCount', per_minute => 1 }, { name => 'display' } ],
                output_template => 'hits: %s',
                perfdatas => [
                    { label => 'appqos_hit_count', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'appqos-policy-dropped-packets', nlabel => 'appqos.policy.packets.dropped.count', set => {
                key_values => [ { name => 'appQosPolicyDropPktCount', diff => 1 }, { name => 'display' } ],
                output_template => 'dropped packets: %s/min',
                perfdatas => [
                    { label => 'appqos_dropped_packets', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'appqos-policy-dropped-bytes', nlabel => 'appqos.policy.dropped.bytes', set => {
                key_values => [ { name => 'appQosPolicyDropByteCount', diff => 1 }, { name => 'display' } ],
                output_template => 'dropped packets (volume): %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'appqos_dropped_packets_bytes', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'appqos-policy-forwarded-packets', nlabel => 'appqos.policy.packets.forwarded.count', set => {
                key_values => [ { name => 'appQosPolicyForwardPktCount', per_minute => 1 }, { name => 'display' } ],
                output_template => 'forwarded packets: %s/min',
                perfdatas => [
                    { label => 'appqos_forwarded_packets', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'appqos-policy-forwarded-bytes', nlabel => 'appqos.policy.forwarded.bytes', set => {
                key_values => [ { name => 'appQosPolicyForwardByteCount', diff => 1 }, { name => 'display' } ],
                output_template => 'forwarded packets (volume): %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'appqos_forwarded_packets_bytes', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-org:s'      => { name => 'filter_org' },
        'filter-rule:s'     => { name => 'filter_rule' },
        'filter-policy:s'   => { name => 'filter_policy' },
    });

    return $self;
}

sub prefix_qospolicy_output {
    my ($self, %options) = @_;

    return "QOS Policy '" . $options{instance_value}->{display} . "' ";
}

sub prefix_appqospolicy_output {
    my ($self, %options) = @_;
    
    return "App QOS Policy '" . $options{instance_value}->{display} . "' ";
}

my $mapping_qos_policy = {
    qosPolicyOrgName            => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.5' },
    qosPolicyName               => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.6' },
    qosPolicyRuleName           => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.7' },
    qosPolicyHitCount           => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.8' },
    qosPolicyDropPktCount       => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.9' },
    qosPolicyDropByteCount      => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.10' },
    qosPolicyForwardPktCount    => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.11' },
    qosPolicyForwardByteCount   => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.12' },
    qosPolicySessionDenyCount   => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.13' },
    qosPolicyDropPktsPPS        => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.14' },
    qosPolicyDropBytesPPS       => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.15' },
    qosPolicyDropPktsKBPS       => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.16' },
    qosPolicyDropBytesKBPS      => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.17' }
};

my $mapping_app_qos_policy = {
    appQosPolicyOrgName             => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.5' },             
    appQosPolicyName                => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.6' },
    appQosPolicyRuleName            => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.7' },
    appQosPolicyHitCount            => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.8' },
    appQosPolicyDropPktCount        => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.9' },
    appQosPolicyDropByteCount       => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.10' },
    appQosPolicyForwardPktCount     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.11' },
    appQosPolicyForwardByteCount    => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.12' },
};

my $oid_qosPolicyEntry = '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1';
my $oid_appQosPolicyEntry = '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{policy} = {};

    $self->{results} = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $oid_qosPolicyEntry,
                start => $mapping_qos_policy->{qosPolicyOrgName}->{oid},
                end => $mapping_qos_policy->{qosPolicyDropBytesKBPS}->{oid} },
            { oid => $oid_appQosPolicyEntry,
                start => $mapping_app_qos_policy->{appQosPolicyOrgName}->{oid},
                end => $mapping_app_qos_policy->{appQosPolicyForwardByteCount}->{oid} }
        ],
        nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}->{$oid_qosPolicyEntry}}) {
        next if ($oid !~ /^$mapping_qos_policy->{qosPolicyOrgName}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_qos_policy, results => $self->{results}->{$oid_qosPolicyEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_org}) && $self->{option_results}->{filter_org} ne '' &&
            $result->{wgPolicyName} !~ /$self->{option_results}->{filter_org}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{qosPolicyOrgName} . "': no matching 'org' filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_policy}) && $self->{option_results}->{filter_policy} ne '' &&
            $result->{wgPolicyName} !~ /$self->{option_results}->{filter_policy}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{qosPolicyName} . "': no matching filter 'policy' .", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_rule}) && $self->{option_results}->{filter_rule} ne '' &&
            $result->{wgPolicyName} !~ /$self->{option_results}->{filter_rule}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{qosPolicyRuleName} . "': no matching filter. 'rule' ", debug => 1);
            next;
        }

        $self->{qospolicy}->{$instance} = { display => $result->{appQosPolicyRuleName}, 
            %$result
        };

    }

    foreach my $oid (keys %{$self->{results}->{$oid_appQosPolicyEntry}}) {
        next if ($oid !~ /^$mapping_app_qos_policy->{appQosPolicyOrgName}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_app_qos_policy, results => $self->{results}->{$oid_appQosPolicyEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_org}) && $self->{option_results}->{filter_org} ne '' &&
            $result->{wgPolicyName} !~ /$self->{option_results}->{filter_org}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{appQosPolicyOrgName} . "': no matching 'org' filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_policy}) && $self->{option_results}->{filter_policy} ne '' &&
            $result->{wgPolicyName} !~ /$self->{option_results}->{filter_policy}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{appQosPolicyName} . "': no matching filter 'policy' .", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_rule}) && $self->{option_results}->{filter_rule} ne '' &&
            $result->{wgPolicyName} !~ /$self->{option_results}->{filter_rule}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{appQosPolicyRuleName} . "': no matching filter. 'rule' ", debug => 1);
            next;
        }

        $self->{appqospolicy}->{$instance} = { display => $result->{appQosPolicyRuleName}, 
            %$result
        };

    }
    
    if (scalar(keys %{$self->{appqospolicy}}) <= 0 && scalar(keys %{$self->{qospolicy}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No policy found. Check your filters");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "versanetworks_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
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

=item B<--filter-org>

Filter monitoring on 'org' -organization name- (can be a regexp).
An org may have 1 to n associated policies and rules

=item B<--filter-policy>

Filter monitoring on 'policy' -policy name- (can be a regexp).
A policy may have 1 to n associated rules

=item B<--filter-rule>

Filter monitoring on 'rule' -rule name- (can be a regexp)
Rules are unique

=item B<--warning-*>

Threshold WARNING for QOS Policy:
Can be: 'qos-policy-hit-count', 'qos-policy-dropped-packets', 'qos-policy-dropped-bytes', 
'qos-policy-forwarded-packets', 'qos-policy-forwarded-bytes'

Threshold WARNING for Applications QOS Policy:
Can be: 'appqos-policy-hit-count', 'appqos-policy-dropped-packets', 
'appqos-policy-dropped-bytes', 'appqos-policy-forwarded-packets', 'appqos-policy-forwarded-bytes'

=item B<--critical-*>

Threshold CRITICAL for QOS Policy:
Can be: 'qos-policy-hit-count', 'qos-policy-dropped-packets', 'qos-policy-dropped-bytes', 
'qos-policy-forwarded-packets', 'qos-policy-forwarded-bytes'

Threshold CRITICAL for Applications QOS Policy:
Can be: 'appqos-policy-hit-count', 'appqos-policy-dropped-packets', 
'appqos-policy-dropped-bytes', 'appqos-policy-forwarded-packets', 'appqos-policy-forwarded-bytes'

=back

=cut
