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

package storage::hp::lefthand::snmp::mode::volumeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'replication status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_clusVolumeReplicationStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volume', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' }
    ];
    
    $self->{maps_counters}->{volume} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'read', set => {
                key_values => [ { name => 'clusVolumeStatsKbytesRead', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read I/O : %s %s/s', output_error_template => "Read I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write', set => {
                key_values => [ { name => 'clusVolumeStatsKbytesWrite', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write I/O : %s %s/s', output_error_template => "Write I/O : %s",
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-iops', set => {
                key_values => [ { name => 'clusVolumeStatsIOsRead', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read IOPs : %.2f', output_error_template => "Read IOPs : %s",
                perfdatas => [
                    { label => 'read_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'clusVolumeStatsIOsWrite', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write IOPs : %.2f', output_error_template => "Write IOPs : %s",
                perfdatas => [
                    { label => 'write_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-latency', set => {
                key_values => [ { name => 'clusVolumeStatsIoLatencyRead', diff => 1 }, { name => 'display' } ],
                output_template => 'Read Latency : %.2f ms', output_error_template => "Read Latency : %s",
                perfdatas => [
                    { label => 'read_latency', template => '%.2f',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-latency', set => {
                key_values => [ { name => 'clusVolumeStatsIoLatencyWrite', diff => 1 }, { name => 'display' } ],
                output_template => 'Write Latency : %.2f ms', output_error_template => "Write Latency : %s",
                perfdatas => [
                    { label => 'write_latency', template => '%.2f',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'replication-status', threshold => 0, set => {
                key_values => [ { name => 'clusVolumeReplicationStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'                 => { name => 'filter_name' },
        'warning-replication-status:s'  => { name => 'warning_replication_status', default => '' },
        'critical-replication-status:s' => { name => 'critical_replication_status', default => '%{status} !~ /normal/i' },
        'units:s'                       => { name => 'units', default => '%' },
        'free'                          => { name => 'free' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_replication_status', 'critical_replication_status']);
}

sub prefix_volume_output {
    my ($self, %options) = @_;
    
    return "Volume '" . $options{instance_value}->{display} . "' ";
}

my %map_replication_status = (1 => 'normal', 2 => 'faulty');
my $mapping = {
    clusVolumeName              => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.2' },
    clusVolumeSize              => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.5' },
    clusVolumeReplicationStatus => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.15', map => \%map_replication_status },
    clusVolumeUsedSpace         => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.31' },
    clusVolumeStatsIOsRead      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.36' },
    clusVolumeStatsIOsWrite     => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.37' },
    clusVolumeStatsKbytesRead   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.38' },
    clusVolumeStatsKbytesWrite  => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.39' },
    clusVolumeStatsIoLatencyRead    => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.42' },
    clusVolumeStatsIoLatencyWrite   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1.43' },
};

my $oid_clusVolumeEntry = '.1.3.6.1.4.1.9804.3.1.1.2.12.97.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    $self->{volume} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_clusVolumeEntry,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{clusVolumeName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{clusVolumeName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{clusVolumeName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $result->{clusVolumeStatsKbytesRead} *= 1024;
        $result->{clusVolumeStatsKbytesWrite} *= 1024;
        $self->{volume}->{$instance} = { 
            display => $result->{clusVolumeName},
            total => $result->{clusVolumeSize} * 1024,
            used => $result->{clusVolumeUsedSpace} * 1024,
            %$result
        };
    }
    
    if (scalar(keys %{$self->{volume}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "hp_lefthand_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^read|write$'

=item B<--filter-name>

Filter volume name (can be a regexp).

=item B<--warning-replication-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-replication-status>

Set critical threshold for status (Default: '%{status} !~ /normal/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'read' (b/s), 'write' (b/s), 'read-iops', 'write-iops',
'read-latency', 'write-latency', 'usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'read' (b/s), 'write' (b/s), 'read-iops', 'write-iops',
'read-latency', 'write-latency', 'usage'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
