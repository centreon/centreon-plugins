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

package centreon::common::cisco::standard::snmp::mode::memoryflash;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_mem_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory flash partitions are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', nlabel => 'memory.flash.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_mem_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.flash.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_mem_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.flash.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /readOnly/i' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Partition '" . $options{instance_value}->{display} . "' ";
}

my $map_status = { 1 => 'readOnly', 2 => 'runFromFlash', 3 => 'readWrite' };

my $mapping = {
    ciscoFlashPartitionSize              => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.4' },
    ciscoFlashPartitionFreeSpace         => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.5' },
    ciscoFlashPartitionStatus            => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.8', map => $map_status },
    ciscoFlashPartitionName              => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.10' },
    ciscoFlashPartitionSizeExtended      => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.13' },
    ciscoFlashPartitionFreeSpaceExtended => { oid => '.1.3.6.1.4.1.9.9.10.1.1.4.1.1.14' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $ciscoFlashPartitionEntry = '.1.3.6.1.4.1.9.9.10.1.1.4.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $ciscoFlashPartitionEntry,
        nothing_quit => 1
    );

    $self->{memory} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ciscoFlashPartitionSize}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ciscoFlashPartitionName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{ciscoFlashPartitionName} . "': no matching filter.", debug => 1);
            next;
        }

        my $total = $result->{ciscoFlashPartitionSize};
        if (defined($result->{ciscoFlashPartitionSizeExtended})) {
            $total = $result->{ciscoFlashPartitionSizeExtended};
        }
        my $free = $result->{ciscoFlashPartitionFreeSpace};
        if (defined($result->{ciscoFlashPartitionFreeSpaceExtended})) {
            $free = $result->{ciscoFlashPartitionFreeSpaceExtended};
        }

        my ($used, $prct_used, $prct_free);
        if ($total > 0) {
            $used = $total - $free;
            $prct_used = $used * 100 / $total;
            $prct_free = 100 - $prct_used;
        }
        $self->{memory}->{$instance} = {
            display => $result->{ciscoFlashPartitionName},
            status => $result->{ciscoFlashPartitionStatus},
            free => $free,
            used => $used,
            prct_used => $prct_used,
            prct_free => $prct_free,
            total => $total,
        };
    }
    
    if (scalar(keys %{$self->{memory}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No flash memory found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory flash usages.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /readOnly/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=item B<--filter-name>

Filter partition name (can be a regexp).

=back

=cut
