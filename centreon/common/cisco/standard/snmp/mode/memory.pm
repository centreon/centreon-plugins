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

package centreon::common::cisco::standard::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel, $unit, $total) = ('used', $self->{nlabel}, '%', 100);
    my $value_perf = $self->{result_values}->{prct_used};
    my %total_options = ();
    if ($self->{result_values}->{total} != -1) {
        $nlabel = 'memory.usage.bytes';
        $unit = 'B';
        $total = $self->{result_values}->{total};
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
        $value_perf = $self->{result_values}->{used};
    }

    $self->{output}->perfdata_add(
        label => $label, unit => $unit,
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $total
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{total} != -1) {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
        $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                       $total_size_value . " " . $total_size_unit,
                       $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                       $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    } else {
        $msg = sprintf("Usage : %.2f %%", $self->{result_values}->{prct_used});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_prct_used'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    if ($self->{result_values}->{total} != -1) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memories are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' }, { name => 'prct_used' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-pool:s'     => { name => 'filter_pool' },
        'check-order:s'     => { name => 'check_order', default => 'enhanced_pool,pool,process,system_ext' },
    });

    return $self;
}

my $mapping_memory_pool = {
    ciscoMemoryPoolName   => { oid => '.1.3.6.1.4.1.9.9.48.1.1.1.2' },
    ciscoMemoryPoolUsed   => { oid => '.1.3.6.1.4.1.9.9.48.1.1.1.5' }, # in B
    ciscoMemoryPoolFree   => { oid => '.1.3.6.1.4.1.9.9.48.1.1.1.6' }, # in B
};
my $oid_ciscoMemoryPoolEntry = '.1.3.6.1.4.1.9.9.48.1.1.1';

sub check_memory_pool {
    my ($self, %options) = @_;

    return if ($self->{checked_memory} == 1);
    
    my $snmp_result = $self->{snmp}->get_table(
        oid => $oid_ciscoMemoryPoolEntry,
        start => $mapping_memory_pool->{ciscoMemoryPoolName}->{oid}, end => $mapping_memory_pool->{ciscoMemoryPoolFree}->{oid}
    );
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping_memory_pool->{ciscoMemoryPoolName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_memory_pool, results => $snmp_result, instance => $instance);

        $self->{checked_memory} = 1;
        if (defined($self->{option_results}->{filter_pool}) && $self->{option_results}->{filter_pool} ne '' &&
            $result->{ciscoMemoryPoolName} !~ /$self->{option_results}->{filter_pool}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ciscoMemoryPoolName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{memory}->{$instance} = {
            display => $result->{ciscoMemoryPoolName},
            total => $result->{ciscoMemoryPoolFree} + $result->{ciscoMemoryPoolUsed},
            used => $result->{ciscoMemoryPoolUsed},
            prct_used => -1,
        };
    }
}

my $oid_cseSysMemoryUtilization = '.1.3.6.1.4.1.9.9.305.1.1.2';

sub check_memory_system_ext {
    my ($self, %options) = @_;
    
    return if ($self->{checked_memory} == 1);
    
    my $snmp_result = $self->{snmp}->get_table(
        oid => $oid_cseSysMemoryUtilization,
    );
    
    foreach my $oid (keys %{$snmp_result}) {
        my $used = $snmp_result->{$oid};
        next if ($used eq '');
        my $display = 'system';

        $self->{checked_memory} = 1;
        if (defined($self->{option_results}->{filter_pool}) && $self->{option_results}->{filter_pool} ne '' &&
            $display !~ /$self->{option_results}->{filter_pool}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }

        $self->{memory}->{system} = {
            display => 'system',
            total => -1,
            used => -1,
            prct_used => $used,
        };
    }
}

my $mapping_enh_memory_pool = {
    cempMemPoolName     => { oid => '.1.3.6.1.4.1.9.9.221.1.1.1.1.3' },
    cempMemPoolUsed     => { oid => '.1.3.6.1.4.1.9.9.221.1.1.1.1.7' }, # in B
    cempMemPoolFree     => { oid => '.1.3.6.1.4.1.9.9.221.1.1.1.1.8' }, # in B
    cempMemPoolHCUsed   => { oid => '.1.3.6.1.4.1.9.9.221.1.1.1.1.18' }, # in B
    cempMemPoolHCFree   => { oid => '.1.3.6.1.4.1.9.9.221.1.1.1.1.20' }, # in B
};

sub check_memory_enhanced_pool {
    my ($self, %options) = @_;

    return if ($self->{checked_memory} == 1);
    
    my $oids = [
        { oid => $mapping_enh_memory_pool->{cempMemPoolName}->{oid} },
        { oid => $mapping_enh_memory_pool->{cempMemPoolUsed}->{oid} },
        { oid => $mapping_enh_memory_pool->{cempMemPoolFree}->{oid} },
    ];
    if (!$self->{snmp}->is_snmpv1()) {
        push @{$oids}, { oid => $mapping_enh_memory_pool->{cempMemPoolHCUsed}->{oid} }, 
            { oid => $mapping_enh_memory_pool->{cempMemPoolHCFree}->{oid} };
    }
    my $snmp_result = $self->{snmp}->get_multiple_table(
        oids => $oids,
        return_type => 1
    );

    my $physical_array = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping_enh_memory_pool->{cempMemPoolName}->{oid}\.(.*?)\.(.*)$/);
        my ($physical_index, $mem_index) = ($1, $2);
        my $result = $self->{snmp}->map_instance(mapping => $mapping_enh_memory_pool, results => $snmp_result, instance => $physical_index . '.' . $mem_index);

        $self->{checked_memory} = 1;
        if (defined($self->{option_results}->{filter_pool}) && $self->{option_results}->{filter_pool} ne '' &&
            $result->{cempMemPoolName} !~ /$self->{option_results}->{filter_pool}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{cempMemPoolName} . "': no matching filter.", debug => 1);
            next;
        }

        my $used = defined($result->{cempMemPoolHCUsed}) ? $result->{cempMemPoolHCUsed} : $result->{cempMemPoolUsed};
        my $free = defined($result->{cempMemPoolHCFree}) ? $result->{cempMemPoolHCFree} : $result->{cempMemPoolFree};
        if ($used + $free <= 0) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{cempMemPoolName} . "': no total.", debug => 1);
            next;
        }

        $physical_array->{$physical_index} = 1;
        $self->{memory}->{$physical_index . '.' . $mem_index} = {
            display => $result->{cempMemPoolName},
            total => $used + $free,
            used => $used,
            prct_used => -1,
            physical_index => $physical_index,
        };
    }

    if (scalar(keys %$physical_array) > 0) {
        my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';
        $self->{snmp}->load(
            oids => [$oid_entPhysicalName],
            instances => [keys %$physical_array],
            instance_regexp => '^(.*)$'
        );
        $snmp_result = $self->{snmp}->get_leef();
        foreach (keys %{$self->{memory}}) {
            if (defined($snmp_result->{ $oid_entPhysicalName . '.' . $self->{memory}->{$_}->{physical_index} })) {
                $self->{memory}->{$_}->{display} = 
                    $snmp_result->{ $oid_entPhysicalName . '.' . $self->{memory}->{$_}->{physical_index} } . '_' . $self->{memory}->{$_}->{display};
            }
        }
    }
}

my $mapping_memory_process = {
    cpmCPUMemoryUsed        => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.12' }, # in KB
    cpmCPUMemoryFree        => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.13' }, # in KB
    cpmCPUMemoryUsedOvrflw  => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.16' }, # in KB
    cpmCPUMemoryFreeOvrflw  => { oid => '.1.3.6.1.4.1.9.9.109.1.1.1.1.18' }, # in KB
};

sub check_memory_process {
    my ($self, %options) = @_;

    return if ($self->{checked_memory} == 1);

    my $oid_cpmCPUTotalEntry = '.1.3.6.1.4.1.9.9.109.1.1.1.1';
    my $snmp_result = $self->{snmp}->get_table(
        oid => $oid_cpmCPUTotalEntry, 
        start => $mapping_memory_process->{cpmCPUMemoryUsed}->{oid},
        end => $mapping_memory_process->{cpmCPUMemoryFreeOvrflw}->{oid},
    );
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping_memory_process->{cpmCPUMemoryUsed}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_memory_process, results => $snmp_result, instance => $instance);

        $self->{checked_memory} = 1;

        my $used = (
            defined($result->{cpmCPUMemoryUsedOvrflw}) ? 
            ($result->{cpmCPUMemoryUsedOvrflw} << 32) + ($result->{cpmCPUMemoryUsed}) :
            $result->{cpmCPUMemoryUsed}
        ) * 1024;
        my $free = (
            defined($result->{cpmCPUMemoryFreeOvrflw}) ? 
            ($result->{cpmCPUMemoryFreeOvrflw} << 32) + ($result->{cpmCPUMemoryFree}) :
            $result->{cpmCPUMemoryFree}
        ) * 1024;
        $self->{memory}->{$instance} = {
            display => $instance,
            total => $used + $free,
            used => $used,
            prct_used => -1,
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{checked_memory} = 0;
    $self->{memory} = {};

    foreach (split /,/, $self->{option_results}->{check_order}) {
        my $method = $self->can('check_memory_' . $_);
        if ($method) {
            $self->$method();
        }
    }

    if ($self->{checked_memory} == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find memory informations");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory usage (CISCO-MEMORY-POOL-MIB, CISCO-ENHANCED-MEMPOOL-MIB, CISCO-PROCESS-MIB, CISCO-SYSTEM-EXT-MIB).

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=item B<--filter-pool>

Filter pool to check (can use regexp).

=item B<--check-order>

Check memory in standard cisco mib. If you have some issue (wrong memory information in a specific mib), you can change the order 
(Default: 'enhanced_pool,pool,process,system_ext').

=back

=cut
    
