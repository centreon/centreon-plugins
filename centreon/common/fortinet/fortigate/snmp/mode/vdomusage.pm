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

package centreon::common::fortinet::fortigate::snmp::mode::vdomusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "operation mode is '%s'- HA cluster member state is '%s'",
        $self->{result_values}->{op_mode},
        $self->{result_values}->{ha_state}
    );
}

sub custom_license_output {
    my ($self, %options) = @_;
        
    return sprintf(
        'number of virtual domains used: %s/%s (%.2f%%)',
        $self->{result_values}->{used},
        $self->{result_values}->{total},
        $self->{result_values}->{prct_used}
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    my ($checked, $total_bits) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_traffic_$options{extra_options}->{label_ref}_(\d+)/) {
            my $new_bits = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_bits = $options{old_datas}->{$_};

            $checked = 1;
            my $diff_bits = $new_bits - $old_bits;
            if ($diff_bits < 0) {
                $total_bits += $new_bits;
            } else {
                $total_bits += $diff_bits;
            }
        }
    }

    if ($checked == 0) {
        $self->{error_msg} = 'buffer creation';
        return -1;
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic_per_second} = $total_bits / $options{delta_time};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    return 0;
}

sub vdom_long_output {
    my ($self, %options) = @_;

    return "checking virtual domain '" . $options{instance_value}->{display} . "'";
}

sub prefix_vdom_output {
    my ($self, %options) = @_;

    return "virtual domain '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'vdom', type => 3, cb_prefix_output => 'prefix_vdom_output', cb_long_output => 'vdom_long_output',
          indent_long_output => '    ', message_multiple => 'All virtual domains are ok',
            group => [
                { name => 'vdom_cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vdom_memory', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vdom_session', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vdom_traffic', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vdom_policy', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vdom_status', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'license-usage', nlabel => 'virtualdomains.license.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'license-free', nlabel => 'virtualdomains.license.free.count', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'license-usage-prct', nlabel => 'virtualdomains.license.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vdom_cpu} = [
        { label => 'cpu-utilization', nlabel => 'virtualdomain.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'cpu usage: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100,
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vdom_memory} = [
        { label => 'memory-usage-prct', nlabel => 'virtualdomain.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'memory used : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ],
            }
        }
    ];

    $self->{maps_counters}->{vdom_policy} = [
        { label => 'policies-active', nlabel => 'virtualdomain.policies.active.count', set => {
                key_values => [ { name => 'active_policies' }, { name => 'display' } ],
                output_template => 'active policies: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        }
    ];

    $self->{maps_counters}->{vdom_session} = [
        { label => 'sessions-active', nlabel => 'virtualdomain.sessions.active.count', set => {
                key_values => [ { name => 'active_sessions' }, { name => 'display' } ],
                output_template => 'active sessions: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        },
        { label => 'sessions-rate', nlabel => 'virtualdomain.sessions.rate.persecond', set => {
                key_values => [ { name => 'session_rate' }, { name => 'display' } ],
                output_template => 'session setup rate: %d/s',
                perfdatas => [
                    { template => '%d', min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vdom_status} = [
         { label => 'status', threshold => 0,  set => {
                key_values => [ { name => 'op_mode' }, { name => 'ha_state' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];

    $self->{maps_counters}->{vdom_traffic} = [
        { label => 'traffic-in', nlabel => 'virtualdomain.traffic.in.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                output_template => 'traffic in: %s%s/s',
                output_use => 'traffic_per_second', threshold_use => 'traffic_per_second',
                output_change_bytes => 2,
                perfdatas => [
                    { value => 'traffic_per_second', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'virtualdomain.traffic.out.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                output_template => 'traffic out: %s%s/s',
                output_use => 'traffic_per_second', threshold_use => 'traffic_per_second',
                output_change_bytes => 2,
                perfdatas => [
                    { value => 'traffic_per_second', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-vdomain:s'    => { name => 'filter_vdomain' },
        'add-traffic'         => { name => 'add_traffic' },
        'add-policy'          => { name => 'add_policy' },
        'policy-cache-time:s' => { name => 'policy_cache_time', default => 60 },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '' }
    });

    $self->{cache_policy} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    $self->{cache_policy}->check_options(%options) if (defined($self->{option_results}->{add_policy}));
}

my $map_opmode = { 1 => 'nat', 2 => 'transparent' };
my $map_ha = { 1 => 'master', 2 => 'backup', 3 => 'standalone' };

my $mapping = {
    fgVdNumber => { oid => '.1.3.6.1.4.1.12356.101.3.1.1' },
    fgVdMaxVdoms => { oid => '.1.3.6.1.4.1.12356.101.3.1.2' }
};
my $mapping_vdom = {
    fgVdEntOpMode   => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.3', map => $map_opmode },
    fgVdEntHaState  => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.4', map => $map_ha },
    fgVdEntCpuUsage => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.5' },
    fgVdEntMemUsage => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.6' },
    fgVdEntSesCount => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.7' },
    fgVdEntSesRate  => { oid => '.1.3.6.1.4.1.12356.101.3.2.1.1.8' }
};

my $oid_fgVdEntName = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';
my $oid_fgVdInfo = '.1.3.6.1.4.1.12356.101.3.1';
my $oid_fgIntfEntVdom = '.1.3.6.1.4.1.12356.101.7.2.1.1.1';

sub add_traffic {
    my ($self, %options) = @_;

    my $traffic_in32  = '.1.3.6.1.2.1.2.2.1.10';
    my $traffic_out32 = '.1.3.6.1.2.1.2.2.1.16';
    my $traffic_in64  = '.1.3.6.1.2.1.31.1.1.1.6';
    my $traffic_out64 = '.1.3.6.1.2.1.31.1.1.1.10';

    my $snmp_result = $options{snmp}->get_table(oid => $oid_fgIntfEntVdom);
    my $indexes = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        my $ifindex = $1;
        if (defined($self->{vdom}->{ $snmp_result->{$_} })) {
            $indexes->{$ifindex} = $snmp_result->{$_};
        }
    }

    my ($in_oid, $out_oid) = ($traffic_in32, $traffic_out32);
    if (!$options{snmp}->is_snmpv1()) {
        ($in_oid, $out_oid) = ($traffic_in64, $traffic_out64);
    }
    $options{snmp}->load(
        oids => [ $in_oid, $out_oid ],
        instances => [ keys %$indexes ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    
    foreach (keys %$indexes) {
        next if (!defined($snmp_result->{$in_oid . '.' . $_}));
        $self->{vdom}->{ $indexes->{$_} }->{vdom_traffic} = { display => $self->{vdom}->{ $indexes->{$_} }->{display} }
            if (!defined($self->{vdom}->{ $indexes->{$_} }->{vdom_traffic}));
        $self->{vdom}->{ $indexes->{$_} }->{vdom_traffic}->{'traffic_in_' . $_} = $snmp_result->{$in_oid . '.' . $_} * 8;
        $self->{vdom}->{ $indexes->{$_} }->{vdom_traffic}->{'traffic_out_' . $_} = $snmp_result->{$out_oid . '.' . $_} * 8;
    }
}

sub add_policy {
    my ($self, %options) = @_;

    my $oid_fgFwPolID  = '.1.3.6.1.4.1.12356.101.5.1.2.1.1.1';

    my $has_cache_file = $self->{cache_policy}->read(statefile => 'fortinet_fortigate_policy_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port());
    my $timestamp_cache = $self->{cache_policy}->get(name => 'last_timestamp');
    my $snmp_result = $self->{cache_policy}->get(name => 'snmp_result');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || !defined($snmp_result) || 
        ((time() - $timestamp_cache) > (($self->{option_results}->{policy_cache_time}) * 60))) {
        $snmp_result = $options{snmp}->get_table(oid => $oid_fgFwPolID);
        $self->{cache_policy}->write(data => { last_timestamp => time(), snmp_result => $snmp_result });
    }

    foreach (keys %$snmp_result) {
        /^$oid_fgFwPolID\.(\d+)/;
        $self->{vdom}->{$1}->{vdom_policy}->{active_policies}++
            if (defined($self->{vdom}->{$1}));
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fgVdInfo },
            { oid => $oid_fgVdEntName }
        ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_fgVdInfo}, instance => 0);
    $self->{global} = {
        used => $result->{fgVdNumber},
        total => $result->{fgVdMaxVdoms},
        free => $result->{fgVdMaxVdoms} - $result->{fgVdNumber},
        prct_used => $result->{fgVdNumber} * 100 / $result->{fgVdMaxVdoms},
        prct_free => 100 - ($result->{fgVdNumber} * 100 / $result->{fgVdMaxVdoms})
    };

    $self->{vdom} = {};
    foreach (keys %{$snmp_result->{$oid_fgVdEntName}}) {
        /\.(\d+)$/;
        my $instance = $1;
        my $name = $snmp_result->{$oid_fgVdEntName}->{$_};

        if (defined($self->{option_results}->{filter_vdomain}) && $self->{option_results}->{filter_vdomain} ne '' &&
            $name !~ /$self->{option_results}->{filter_vdomain}/) {
            $self->{output}->output_add(long_msg => "skipping virtual domain '" . $name . "'.", debug => 1);
            next;
        }

        $self->{vdom}->{$instance} = {
            display => $name,
            vdom_cpu => { display => $name },
            vdom_memory => { display => $name },
            vdom_session => { display => $name },
            vdom_status => { display => $name }
        };
        $self->{vdom}->{$instance}->{vdom_policy} = { display => $name, active_policies => 0 }
            if (defined($self->{option_results}->{add_policy}));
    }

    return if (scalar(keys %{$self->{vdom}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_vdom)) ],
        instances => [ keys %{$self->{vdom}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{vdom}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping_vdom, results => $snmp_result, instance => $_);
        $self->{vdom}->{$_}->{vdom_cpu}->{cpu} = $result->{fgVdEntCpuUsage};
        $self->{vdom}->{$_}->{vdom_memory}->{prct_used} = $result->{fgVdEntMemUsage};
        $self->{vdom}->{$_}->{vdom_status}->{op_mode} = $result->{fgVdEntOpMode};
        $self->{vdom}->{$_}->{vdom_status}->{ha_state} = $result->{fgVdEntHaState};
        $self->{vdom}->{$_}->{vdom_session}->{active_sessions} = $result->{fgVdEntSesCount};
        $self->{vdom}->{$_}->{vdom_session}->{session_rate} = $result->{fgVdEntSesRate};
    }

    $self->add_traffic(snmp => $options{snmp})
        if (defined($self->{option_results}->{add_traffic}));
    $self->add_policy(snmp => $options{snmp})
        if (defined($self->{option_results}->{add_policy}));

    $self->{cache_name} = 'fortinet_fortigate_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_vdomain}) ? md5_hex($self->{option_results}->{filter_vdomain}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual domains.

=over 8

=item B<--filter-vdomain>

Filter by virtual domain name (can be a regexp).

=item B<--add-traffic>

Add traffic usage by virtual domain.

=item B<--add-policy>

Add number of policies by virtual domain.

=item B<--policy-cache-time>

Time in minutes before reloading cache file (default: 60).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{op_mode}, %{ha_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{op_mode}, %{ha_state}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization', 'sessions-active', 'session-rate',
'memory-usage-prct', 'license-usage', 'license-free',
'license-usage-prct', 'traffic-in', 'traffic-out', 'policies-active'.

=back

=cut
