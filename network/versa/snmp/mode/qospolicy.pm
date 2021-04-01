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

package network::versa::snmp::mode::qospolicy;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_bytespersecond_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B/s',
        instances => [
            $self->{result_values}->{org_name},
            $self->{result_values}->{policy_name},
            $self->{result_values}->{rule_name}
        ],
        value => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_count_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{org_name},
            $self->{result_values}->{policy_name},
            $self->{result_values}->{rule_name}
        ],
        value => sprintf('%s', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'qospolicy', type => 1, cb_prefix_output => 'prefix_qospolicy_output', message_multiple => 'All QoS policies are ok' },
        { name => 'appqospolicy', type => 1, cb_prefix_output => 'prefix_appqospolicy_output', message_multiple => 'All applications QoS policies are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{qospolicy} = [
        { label => 'qos-policy-hit', nlabel => 'qos.policy.hit.count', set => {
                key_values => [
                    { name => 'hit_count', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'hits: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'qos-policy-sessions-deny', nlabel => 'qos.policy.sessions.deny.count', set => {
                key_values => [
                    { name => 'sessions_deny', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'sessions deny: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'qos-policy-packets-dropped', nlabel => 'qos.policy.packets.dropped.count', set => {
                key_values => [
                    { name => 'drop_pkts', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'packets dropped: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'qos-policy-traffic-dropped', nlabel => 'qos.policy.traffic.dropped.bytespersecond', set => {
                key_values => [
                    { name => 'drop_bytes', per_second => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'traffic dropped: %.2f %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_bytespersecond_perfdata')
            }
        },
        { label => 'qos-policy-packets-forwarded', nlabel => 'qos.policy.packets.forwarded.count', display => 0, set => {
                key_values => [
                    { name => 'forward_pkts', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'packets forwarded: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'qos-policy-traffic-forwarded', nlabel => 'qos.policy.traffic.forwarded.bytespersecond', set => {
                key_values => [
                    { name => 'forward_bytes', per_second => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'traffic forwarded: %.2f %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_bytespersecond_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{appqospolicy} = [
        { label => 'appqos-policy-hit', nlabel => 'appqos.policy.hit.count', set => {
                key_values => [
                    { name => 'hit_count', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'hits: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'appqos-policy-packets-dropped', nlabel => 'appqos.policy.packets.dropped.count', display_ok => 0, set => {
                key_values => [
                    { name => 'drop_pkts', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'packets dropped: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'appqos-policy-traffic-dropped', nlabel => 'appqos.policy.traffic.dropped.bytespersecond', set => {
                key_values => [
                    { name => 'drop_bytes', per_second => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'traffic dropped: %.2f %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_bytespersecond_perfdata')
            }
        },
        { label => 'appqos-policy-packets-forwarded', nlabel => 'appqos.policy.packets.forwarded.count', display_ok => 0, set => {
                key_values => [
                    { name => 'forward_pkts', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'packets forwarded: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'appqos-policy-traffic-forwarded', nlabel => 'appqos.policy.traffic.forwarded.bytespersecond', set => {
                key_values => [
                    { name => 'forward_bytes', per_second => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'traffic forwarded: %.2f %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_bytespersecond_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-org:s'    => { name => 'filter_org' },
        'filter-rule:s'   => { name => 'filter_rule' },
        'filter-policy:s' => { name => 'filter_policy' }
    });

    return $self;
}

sub prefix_qospolicy_output {
    my ($self, %options) = @_;

    return sprintf(
        "QoS policy '%s' [org: %s] [policy: %s] ",
        $options{instance_value}->{rule_name},
        $options{instance_value}->{org_name},
        $options{instance_value}->{policy_name}
    );
}

sub prefix_appqospolicy_output {
    my ($self, %options) = @_;

    return sprintf(
        "Application QoS policy '%s' [org: %s] [policy: %s] ",
        $options{instance_value}->{rule_name},
        $options{instance_value}->{org_name},
        $options{instance_value}->{policy_name}
    );
}

my $mapping_qos_policy = {
    org_name      => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.5' }, # qosPolicyOrgName
    policy_name   => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.6' }, # qosPolicyName
    rule_name     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.7' }, # qosPolicyRuleName
    hit_count     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.8' }, # qosPolicyHitCount
    drop_pkts     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.9' }, # qosPolicyDropPktCount
    drop_bytes    => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.10' }, # qosPolicyDropByteCount
    forward_pkts  => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.11' }, # qosPolicyForwardPktCount
    forward_bytes => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.12' }, # qosPolicyForwardByteCount
    sessions_deny => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1.13' } # qosPolicySessionDenyCount
};

my $mapping_app_qos_policy = {
    org_name      => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.5' }, # appQosPolicyOrgName    
    policy_name   => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.6' }, # appQosPolicyName
    rule_name     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.7' }, # appQosPolicyRuleName
    hit_count     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.8' }, # appQosPolicyHitCount
    drop_pkts     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.9' }, # appQosPolicyDropPktCount
    drop_bytes    => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.10' }, # appQosPolicyDropByteCount
    forward_pkts  => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.11' }, # appQosPolicyForwardPktCount
    forward_bytes => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1.12' } # appQosPolicyForwardByteCount
};

my $oid_qosPolicyEntry = '.1.3.6.1.4.1.42359.2.2.1.2.1.5.1.1';
my $oid_appQosPolicyEntry = '.1.3.6.1.4.1.42359.2.2.1.2.1.5.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ 
            {
                oid => $oid_qosPolicyEntry,
                start => $mapping_qos_policy->{org_name}->{oid},
                end => $mapping_qos_policy->{sessions_deny}->{oid}
            },
            {
                oid => $oid_appQosPolicyEntry,
                start => $mapping_app_qos_policy->{org_name}->{oid},
                end => $mapping_app_qos_policy->{forward_bytes}->{oid}
            }
        ],
        nothing_quit => 1
    );

    $self->{qospolicy} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_qosPolicyEntry}}) {
        next if ($oid !~ /^$mapping_qos_policy->{org_name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_qos_policy, results => $snmp_result->{$oid_qosPolicyEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_org}) && $self->{option_results}->{filter_org} ne '' &&
            $result->{org_name} !~ /$self->{option_results}->{filter_org}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{org_name} . "': no matching 'org' filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_policy}) && $self->{option_results}->{filter_policy} ne '' &&
            $result->{policy_name} !~ /$self->{option_results}->{filter_policy}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{policy_name} . "': no matching filter 'policy' .", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_rule}) && $self->{option_results}->{filter_rule} ne '' &&
            $result->{rule_name} !~ /$self->{option_results}->{filter_rule}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{rule_name} . "': no matching filter. 'rule' ", debug => 1);
            next;
        }

        $self->{qospolicy}->{$instance} = $result;
    }

    $self->{appqospolicy} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_appQosPolicyEntry}}) {
        next if ($oid !~ /^$mapping_app_qos_policy->{org_name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_app_qos_policy, results => $snmp_result->{$oid_appQosPolicyEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_org}) && $self->{option_results}->{filter_org} ne '' &&
            $result->{org_name} !~ /$self->{option_results}->{filter_org}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{org_name} . "': no matching 'org' filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_policy}) && $self->{option_results}->{filter_policy} ne '' &&
            $result->{policy_name} !~ /$self->{option_results}->{filter_policy}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{policy_name} . "': no matching filter 'policy' .", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_rule}) && $self->{option_results}->{filter_rule} ne '' &&
            $result->{rule_name} !~ /$self->{option_results}->{filter_rule}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{rule_name} . "': no matching filter. 'rule' ", debug => 1);
            next;
        }

        $self->{appqospolicy}->{$instance} = $result;
    }

    if (scalar(keys %{$self->{appqospolicy}}) <= 0 && scalar(keys %{$self->{qospolicy}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No policy found. Check your filters');
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = 'versanetworks_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_org}) ? md5_hex($self->{option_results}->{filter_org}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_rule}) ? md5_hex($self->{option_results}->{filter_rule}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_policy}) ? md5_hex($self->{option_results}->{filter_policy}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check QoS policies.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='qos-policy-hit'

=item B<--filter-org>

Filter monitoring on 'org' -organization name- (can be a regexp).
An org may have 1 to n associated policies and rules

=item B<--filter-policy>

Filter monitoring on 'policy' -policy name- (can be a regexp).
A policy may have 1 to n associated rules

=item B<--filter-rule>

Filter monitoring on 'rule' -rule name- (can be a regexp)

=item B<--warning-*> B<--critical-*>

Thresholds for QoS policy:
Can be: 'qos-policy-hit', 'qos-policy-sessions-deny', 'qos-policy-packets-dropped', 'qos-policy-traffic-dropped',
'qos-policy-packets-forwarded', 'qos-policy-traffic-forwarded'.

Thresholds for applications QoS policy:
Can be: 'appqos-policy-hit', 'appqos-policy-packets-dropped', 'appqos-policy-traffic-dropped',
'appqos-policy-packets-forwarded', 'appqos-policy-traffic-forwarded'.

=back

=cut
