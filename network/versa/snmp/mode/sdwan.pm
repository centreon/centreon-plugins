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

package network::versa::snmp::mode::sdwan;

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
        { name => 'sdwan', type => 1, cb_prefix_output => 'prefix_sdwan_output', message_multiple => 'All SD-Wan are ok' }
    ];

    $self->{maps_counters}->{sdwan} = [
        { label => 'hit', nlabel => 'sdwan.policy.hit.count', set => {
                key_values => [
                    { name => 'hit_count', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'hits: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'packets-in', nlabel => 'sdwan.policy.packets.in.count', display_ok => 0, set => {
                key_values => [
                    { name => 'in_pkts', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'packets in: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'traffic-in', nlabel => 'sdwan.policy.traffic.in.bytespersecond', set => {
                key_values => [
                    { name => 'in_bytes', per_second => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'traffic in: %.2f %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_bytespersecond_perfdata')
            }
        },
        { label => 'packets-out', nlabel => 'sdwan.policy.packets.out.count', display_ok => 0, set => {
                key_values => [
                    { name => 'out_pkts', diff => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'packets out: %s',
                closure_custom_perfdata => $self->can('custom_count_perfdata')
            }
        },
        { label => 'traffic-out', nlabel => 'sdwan.policy.traffic.out.bytespersecond', set => {
                key_values => [
                    { name => 'out_bytes', per_second => 1 }, { name => 'org_name' },
                    { name => 'policy_name' }, { name => 'rule_name' }
                ],
                output_template => 'traffic out: %.2f %s/s',
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

sub prefix_sdwan_output {
    my ($self, %options) = @_;

    return sprintf(
        "SD-Wan rule '%s' [org: %s] [policy: %s] ",
        $options{instance_value}->{rule_name},
        $options{instance_value}->{org_name},
        $options{instance_value}->{policy_name}
    );
}

my $mapping_name = {
    org_name    => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.5' }, # sdwanPolicyOrgName    
    policy_name => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.6' }, # sdwanPolicyName
    rule_name   => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.7' }  # sdwanPolicyRuleName
};

my $mapping_stats = {
    hit_count => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.8' },  # sdwanPolicyHitCount
    out_pkts  => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.13' }, # sdwanPolicyTxPktsTunnel
    out_bytes => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.14' }, # sdwanPolicyTxBytesTunnel
    in_pkts   => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.15' }, # sdwanPolicyRxPktsTunnel
    in_bytes  => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1.16' }  # sdwanPolicyRxBytesTunnel
};
my $oid_sdwanPolicyEntry = '.1.3.6.1.4.1.42359.2.2.1.2.1.10.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_sdwanPolicyEntry,
        start => $mapping_name->{org_name}->{oid},
        end => $mapping_name->{rule_name}->{oid},
        nothing_quit => 1
    );

    $self->{sdwan} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_name->{org_name}->{oid}\.(.*)$/);
        my $instance = $1;
    
        my $result = $options{snmp}->map_instance(mapping => $mapping_name, results => $snmp_result, instance => $instance);
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

        $self->{sdwan}->{$instance} = $result;
    }

    if (scalar(keys %{$self->{sdwan}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No SD-Wan rules found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping_stats))
        ],
        instances => [keys %{$self->{sdwan}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{sdwan}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping_stats, results => $snmp_result, instance => $_);

        $self->{sdwan}->{$_} = { %{$self->{sdwan}->{$_}}, %$result };
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

Check SD-Wan rules.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='traffic'

=item B<--filter-org>

Filter monitoring on 'org' -organization name- (can be a regexp).
An org may have 1 to n associated policies and rules

=item B<--filter-policy>

Filter monitoring on 'policy' -policy name- (can be a regexp).
A policy may have 1 to n associated rules

=item B<--filter-rule>

Filter monitoring on 'rule' -rule name- (can be a regexp)

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'hit', 'packets-in', 'traffic-in', 'packets-out', 'traffic-out'.

=back

=cut
