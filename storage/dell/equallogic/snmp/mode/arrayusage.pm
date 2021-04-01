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

package storage::dell::equallogic::snmp::mode::arrayusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_write_avg_latency_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_op = $options{new_datas}->{$self->{instance} . '_eqlMemberWriteOpCount'} - $options{old_datas}->{$self->{instance} . '_eqlMemberWriteOpCount'};
    my $diff_latency = $options{new_datas}->{$self->{instance} . '_eqlMemberWriteLatency'} - $options{old_datas}->{$self->{instance} . '_eqlMemberWriteLatency'};
    if ($diff_op == 0) {
        $self->{result_values}->{write_avg_latency} = 0;
    } else {
        $self->{result_values}->{write_avg_latency} = $diff_latency / $diff_op;
    }
    
    return 0;
}

sub custom_read_avg_latency_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_op = $options{new_datas}->{$self->{instance} . '_eqlMemberReadOpCount'} - $options{old_datas}->{$self->{instance} . '_eqlMemberReadOpCount'};
    my $diff_latency = $options{new_datas}->{$self->{instance} . '_eqlMemberReadLatency'} - $options{old_datas}->{$self->{instance} . '_eqlMemberReadLatency'};
     if ($diff_op == 0) {
        $self->{result_values}->{read_avg_latency} = 0;
    } else {
        $self->{result_values}->{read_avg_latency} = $diff_latency / $diff_op;
    }
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_eqlMemberTotalStorage'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_eqlMemberUsedStorage'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'array', type => 1, cb_prefix_output => 'prefix_array_output', message_multiple => 'All array usages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{array} = [
        { label => 'used', set => {
                key_values => [ { name => 'display' }, { name => 'eqlMemberTotalStorage' }, { name => 'eqlMemberUsedStorage' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
        { label => 'snapshot', set => {
                key_values => [ { name => 'eqlMemberSnapStorage' }, { name => 'display' } ],
                output_template => 'Snapshot usage : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'snapshost', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'replication', set => {
                key_values => [ { name => 'eqlMemberReplStorage' }, { name => 'display' } ],
                output_template => 'Replication usage : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'replication', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'connections', set => {
                key_values => [ { name => 'eqlMemberNumberOfConnections' }, { name => 'display' } ],
                output_template => 'iSCSI connections : %s',
                perfdatas => [
                    { label => 'connections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'ext-connections', display_ok => 0, set => {
                key_values => [ { name => 'eqlMemberNumberOfExtConnections' }, { name => 'display' } ],
                output_template => 'External iSCSI connections : %s',
                perfdatas => [
                    { label => 'ext_connections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'global-read-avg-latency', display_ok => 0, set => {
                key_values => [ { name => 'eqlMemberReadAvgLatency' }, { name => 'display' } ],
                output_template => 'Global read average latency : %s ms',
                perfdatas => [
                    { label => 'global_read_avg_latency', template => '%s',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'global-write-avg-latency', display_ok => 0, set => {
                key_values => [ { name => 'eqlMemberWriteAvgLatency' }, { name => 'display' } ],
                output_template => 'Global write average latency : %s ms',
                perfdatas => [
                    { label => 'global_write_avg_latency', template => '%s',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'read-avg-latency', set => {
                key_values => [ { name => 'eqlMemberReadLatency', diff => 1 }, { name => 'eqlMemberReadOpCount', diff => 1 }, { name => 'display' } ],
                output_template => 'Read average latency : %.2f ms', threshold_use => 'read_avg_latency', output_use => 'read_avg_latency',
                closure_custom_calc => $self->can('custom_read_avg_latency_calc'),
                perfdatas => [
                    { label => 'read_avg_latency', value => 'read_avg_latency', template => '%.2f',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-avg-latency', display_ok => 0, set => {
                key_values => [ { name => 'eqlMemberWriteLatency', diff => 1 }, { name => 'eqlMemberWriteOpCount', diff => 1 }, { name => 'display' } ],
                output_template => 'Write average latency : %.2f ms', threshold_use => 'write_avg_latency', output_use => 'write_avg_latency',
                closure_custom_calc => $self->can('custom_write_avg_latency_calc'),
                perfdatas => [
                    { label => 'write_avg_latency', value => 'write_avg_latency', template => '%.2f',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'read-iops', set => {
                key_values => [ { name => 'eqlMemberReadOpCount', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read IOPs : %.2f',
                perfdatas => [
                    { label => 'read_iops',  template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'eqlMemberWriteOpCount', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write IOPs : %.2f',
                perfdatas => [
                    { label => 'write_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in', display_ok => 0, set => {
                key_values => [ { name => 'eqlMemberRxData', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%s',
                      unit => 'b/s', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', display_ok => 0, set => {
                key_values => [ { name => 'eqlMemberTxData', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%s',
                      unit => 'b/s', min => 0, cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_array_output {
    my ($self, %options) = @_;

    return "Array '" . $options{instance_value}->{display} . "' ";
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

my $mapping = {
    eqlMemberTotalStorage           => { oid => '.1.3.6.1.4.1.12740.2.1.10.1.1' }, # MB
    eqlMemberUsedStorage            => { oid => '.1.3.6.1.4.1.12740.2.1.10.1.2' }, # MB
    eqlMemberSnapStorage            => { oid => '.1.3.6.1.4.1.12740.2.1.10.1.3' }, # MB
    eqlMemberReplStorage            => { oid => '.1.3.6.1.4.1.12740.2.1.10.1.4' }, # MB

    eqlMemberNumberOfConnections    => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.1' },
    eqlMemberReadLatency            => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.2' },
    eqlMemberWriteLatency           => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.3' },
    eqlMemberReadAvgLatency         => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.4' },
    eqlMemberWriteAvgLatency        => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.5' },
    eqlMemberReadOpCount            => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.6' },
    eqlMemberWriteOpCount           => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.7' },
    eqlMemberTxData                 => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.8' },
    eqlMemberRxData                 => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.9' },
    eqlMemberNumberOfExtConnections => { oid => '.1.3.6.1.4.1.12740.2.1.12.1.10' }
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_eqlMemberName = '.1.3.6.1.4.1.12740.2.1.1.1.9';
    
    $self->{array} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_eqlMemberName, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_eqlMemberName\.(.*)$/;
        my $instance = $1;
        my $name = $snmp_result->{$oid_eqlMemberName . '.' . $instance};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping array '" . $name . "'.", debug => 1);
            next;
        }

        $self->{array}->{$instance} = { display => $name };
    }

    if (scalar(keys %{$self->{array}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
    
    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [keys %{$self->{array}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{array}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $result->{eqlMemberTxData} *= 8 if (defined($result->{eqlMemberTxData}));
        $result->{eqlMemberRxData} *= 8 if (defined($result->{eqlMemberRxData}));

        $result->{eqlMemberTotalStorage} *= 1024 * 1024;
        $result->{eqlMemberUsedStorage} *= 1024 * 1024;
        $result->{eqlMemberSnapStorage} *= 1024 * 1024;
        $result->{eqlMemberReplStorage} *= 1024 * 1024;

        $self->{array}->{$_} = { %{$self->{array}->{$_}}, %$result };
    }

    $self->{cache_name} = 'dell_equallogic_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check array member usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'used' (%), 'snapshot' (B), 'replication' (B),
'connections', 'ext-connections', 'global-read-avg-latency' (ms), 'global-write-avg-latency'  (ms),
'read-avg-latency' (ms), 'write-avg-latency' (ms), 'read-iops' (iops), 'write-iops' (iops), 'traffic-in' (b/s), 'traffic-out' (b/s).

=item B<--critical-*>

Threshold critical.
Can be: 'used' (%), 'snapshot' (B), 'replication' (B),
'connections', 'ext-connections', 'global-read-avg-latency' (ms), 'global-write-avg-latency'  (ms),
'read-avg-latency' (ms), 'write-avg-latency' (ms), 'read-iops' (iops), 'write-iops' (iops), 'traffic-in' (b/s), 'traffic-out' (b/s).

=item B<--filter-name>

Filter array name (can be a regexp).

=back

=cut
