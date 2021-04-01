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

package network::checkpoint::snmp::mode::vsx;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub vsx_long_output {
    my ($self, %options) = @_;

    return "checking virtual system '" . $options{instance_value}->{display} . "'";
}

sub prefix_vsx_output {
    my ($self, %options) = @_;

    return "virtual system '" . $options{instance_value}->{display} . "' ";
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'cpu usage: ';
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vsx', type => 3, cb_prefix_output => 'prefix_vsx_output', cb_long_output => 'vsx_long_output',
          indent_long_output => '    ', message_multiple => 'All virtual systems are ok',
            group => [
                { name => 'vsx_cpu', type => 0, cb_prefix_output => 'prefix_cpu_output', skipped_code => { -10 => 1 } },
                { name => 'vsx_memory', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vsx_connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vsx_traffic', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{vsx_cpu} = [
        { label => 'cpu-utilization-1hour', nlabel => 'virtualsystem.cpu.utilization.1hour.percentage', set => {
                key_values => [ { name => 'cpu_1hour' }, { name => 'display' } ],
                output_template => '%.2f%% (1hour)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cpu-utilization-1min', nlabel => 'virtualsystem.cpu.utilization.1min.percentage', set => {
                key_values => [ { name => 'cpu_1min' }, { name => 'display' } ],
                output_template => '%.2f%% (1min)',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vsx_memory} = [
        { label => 'memory-usage', nlabel => 'virtualsystem.memory.usage.bytes', set => {
                key_values => [ { name => 'memory_used' }, { name => 'display' } ],
                output_template => 'memory used: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vsx_connection} = [
        { label => 'connections-active', nlabel => 'virtualsystem.connections.active.count', set => {
                key_values => [ { name => 'active_connections' }, { name => 'display' } ],
                output_template => 'active connections: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vsx_traffic} = [
        { label => 'traffic-accepted', nlabel => 'virtualsystem.traffic.accepted.bitspersecond', set => {
                key_values => [ { name => 'traffic_accepted', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic accepted: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-dropped', nlabel => 'virtualsystem.traffic.dropped.bitspersecond', set => {
                key_values => [ { name => 'traffic_dropped', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic dropped: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-rejected', nlabel => 'virtualsystem.traffic.rejected.bitspersecond', set => {
                key_values => [ { name => 'traffic_rejected', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic rejected: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
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
        'filter-vsx:s'    => { name => 'filter_vsx' }
    });

    return $self;
}

my $mapping = {
    cpu_1min           => { oid => '.1.3.6.1.4.1.2620.1.16.22.2.1.3' },  # vsxStatusCPUUsage1min
    cpu_1hour          => { oid => '.1.3.6.1.4.1.2620.1.16.22.2.1.4' },  # vsxStatusCPUUsage1hr
    memory_used        => { oid => '.1.3.6.1.4.1.2620.1.16.22.3.1.3' },  # vsxStatusMemoryUsage (KB)
    active_connections => { oid => '.1.3.6.1.4.1.2620.1.16.23.1.1.2' },  # vsxCountersConnNum
    traffic_accepted   => { oid => '.1.3.6.1.4.1.2620.1.16.23.1.1.9' },  # vsxCountersBytesAcceptedTotal
    traffic_dropped    => { oid => '.1.3.6.1.4.1.2620.1.16.23.1.1.10' }, # vsxCountersBytesDroppedTotal
    traffic_rejected   => { oid => '.1.3.6.1.4.1.2620.1.16.23.1.1.11' }  # vsxCountersBytesRejectedTotal
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_vsxStatusVsName = '.1.3.6.1.4.1.2620.1.16.22.1.1.3';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_vsxStatusVsName,
        nothing_quit => 1
    );

    $self->{vsx} = {};
    foreach (keys %$snmp_result) {
        /^$oid_vsxStatusVsName\.(.*)/;
        my $instance = $1;
        my $name = $snmp_result->{$_};

        if (defined($self->{option_results}->{filter_vsx}) && $self->{option_results}->{filter_vsx} ne '' &&
            $name !~ /$self->{option_results}->{filter_vsx}/) {
            $self->{output}->output_add(long_msg => "skipping virtual system '" . $name . "'.", debug => 1);
            next;
        }

        $self->{vsx}->{$instance} = {
            display => $name,
            vsx_cpu => { display => $name },
            vsx_memory => { display => $name },
            vsx_connection => { display => $name },
            vsx_traffic => { display => $name }
        };
    }

    return if (scalar(keys %{$self->{vsx}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %{$self->{vsx}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{vsx}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        $self->{vsx}->{$_}->{vsx_cpu}->{cpu_1min} = $result->{cpu_1min};
        $self->{vsx}->{$_}->{vsx_cpu}->{cpu_1hour} = $result->{cpu_1hour};
        $self->{vsx}->{$_}->{vsx_memory}->{memory_used} = $result->{memory_used} * 1024;
        $self->{vsx}->{$_}->{vsx_connection}->{active_connections} = $result->{active_connections};
        $self->{vsx}->{$_}->{vsx_traffic}->{traffic_accepted} = $result->{traffic_accepted} * 8;
        $self->{vsx}->{$_}->{vsx_traffic}->{traffic_dropped} = $result->{traffic_dropped} * 8;
        $self->{vsx}->{$_}->{vsx_traffic}->{traffic_rejected} = $result->{traffic_rejected} * 8;
    }

    $self->{cache_name} = 'checkpoint_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_vsx}) ? md5_hex($self->{option_results}->{filter_vsx}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual systems.

=over 8

=item B<--filter-vsx>

Filter by virtual system name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-usage', 'traffic-accepted', 'traffic-dropped',
'traffic-rejected', 'cpu-utilization-1hour', 'cpu-utilization-1min',
'connections-active'.

=back

=cut
