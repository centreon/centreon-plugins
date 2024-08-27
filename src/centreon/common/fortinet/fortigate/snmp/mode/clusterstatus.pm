#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::snmp::mode::clusterstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [hostname: %s] [role: %s] [checksum: %s]",
        $self->{result_values}->{sync_status},
        $self->{result_values}->{hostname},
        $self->{result_values}->{role},
        $self->{result_values}->{checksum}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Nodes ';
}

sub node_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking node '%s'",
        $options{instance_value}->{serial}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' ",
        $options{instance_value}->{serial}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    $self->{result_values}->{sync_status} = $options{new_datas}->{$self->{instance} . '_sync_status'};
    $self->{result_values}->{hostname} = $options{new_datas}->{$self->{instance} . '_hostname'};
    $self->{result_values}->{checksum} = $options{new_datas}->{$self->{instance} . '_checksum'};
    $self->{result_values}->{serial} = $options{new_datas}->{$self->{instance} . '_serial'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output',
          indent_long_output => '    ', message_multiple => 'All cluster nodes are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-nodes', nlabel => 'cluster.nodes.count', set => {
                key_values => [ { name => 'total_nodes' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'synchronized', nlabel => 'cluster.nodes.synchronized.count', set => {
                key_values => [ { name => 'synchronized' } ],
                output_template => 'synchronized: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'unsynchronized', nlabel => 'cluster.nodes.unsynchronized.count',set => {
                key_values => [ { name => 'unsynchronized' } ],
                output_template => 'unsynchronized: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'total-checksums', nlabel => 'cluster.checksums.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total_checksums' } ],
                output_template => 'checksums: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        { label => 'status', type => 2, critical_default => '%{role} ne %{roleLast} or %{sync_status} =~ /unsynchronized/', set => {
                key_values => [ { name => 'serial' }, { name => 'hostname' }, { name => 'sync_status' }, { name => 'role' }, { name => 'checksum' } ],
                closure_custom_calc => \&custom_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
         { label => 'cpu-utilization', nlabel => 'node.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'serial' } ],
                output_template => 'cpu usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'serial' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
         { label => 'memory-usage', nlabel => 'node.memory.usage.percentage', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'serial' } ],
                output_template => 'memory used: %.2f %%',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'serial' }
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
        'one-node-status:s' => { name => 'one_node_status' } # not used, use --opt-exit instead
    });

    return $self;
}

my $map_ha_mode = {
    1 => 'standalone',
    2 => 'activeActive',
    3 => 'activePassive'
};
my $map_sync_status = {
    0 => 'unsynchronized',
    1 => 'synchronized'
};

my $mapping = {
    cpuUsage       => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.3' }, # fgHaStatsCpuUsage
    memUsage       => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.4' }, # fgHaStatsMemUsage
    hostname       => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.11' }, # fgHaStatsHostname
    syncStatus     => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.12', map => $map_sync_status }, # fgHaStatsSyncStatus
    globalChecksum => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.15' }, # fgHaStatsGlobalChecksum
    masterSerial   => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.16' } # fgHaStatsMasterSerial
};
my $oid_fgHaSystemMode = '.1.3.6.1.4.1.12356.101.13.1.1.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $mode = $options{snmp}->get_leef(oids => [ $oid_fgHaSystemMode ], nothing_quit => 1);
    
    if ($map_ha_mode->{ $mode->{$oid_fgHaSystemMode} } =~ /standalone/) {
        $self->{output}->add_option_msg(short_msg => "No cluster configuration (standalone mode)");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(short_msg => 'High-availibility mode: ' . $map_ha_mode->{ $mode->{$oid_fgHaSystemMode} });

    my $oid_serial = '.1.3.6.1.4.1.12356.101.13.2.1.1.2'; # fgHaStatsSerial
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_serial,
        nothing_quit => 1
    );

    $self->{global} = { synchronized => 0, unsynchronized => 0, total_nodes => 0 };
    $self->{nodes} = {};
    foreach (keys %$snmp_result) {
        /^$oid_serial\.(.*)$/;
        my $instance = $1;

        $self->{nodes}->{$instance} = { serial => $snmp_result->{$_} };
    }

    return if (scalar(keys %{$self->{nodes}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_, keys(%{$self->{nodes}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    my $checksums = {};
    foreach (keys %{$self->{nodes}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $checksums->{ $result->{globalChecksum} } = 1;
        $self->{nodes}->{$_}->{status} = {
            serial => $self->{nodes}->{$_}->{serial},
            hostname => $result->{hostname},
            sync_status => $result->{syncStatus},
            role => ($result->{masterSerial} eq '' || $result->{masterSerial} =~ /$self->{nodes}->{$_}->{serial}/) ? 'master' : 'slave',
            checksum => $result->{globalChecksum}
        };
        $self->{nodes}->{$_}->{cpu} = { cpu_usage => $result->{cpuUsage}, serial => $self->{nodes}->{$_}->{serial} };
        $self->{nodes}->{$_}->{memory} = { memory_usage => $result->{memUsage}, serial => $self->{nodes}->{$_}->{serial} };

        $self->{global}->{ $result->{syncStatus} }++;
        $self->{global}->{total_nodes}++;
    }

    $self->{global}->{total_checksums} = scalar(keys %$checksums);

    $self->{cache_name} = 'fortinet_fortigate_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check cluster status.

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{serial}, %{hostname}, %{sync_status}, %{role}, %{roleLast}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{role} ne %{roleLast} or %{sync_status} =~ /unsynchronized/').
You can use the following variables: %{serial}, %{hostname}, %{sync_status}, %{role}, %{roleLast}

=item B<--warning-*> B<--critical-*>

Set thresholds.
Can be: 'total-nodes', 'synchronized', 'unsynchronized',
'total-checksums', 'cpu-utilization', 'memory-usage'.

=back

=cut
