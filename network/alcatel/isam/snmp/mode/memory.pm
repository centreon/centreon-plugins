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

package network::alcatel::isam::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'memory.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        nlabel => $nlabel,
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
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memories are ok' },
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"       => { name => 'filter_name' },
        "units:s"             => { name => 'units', default => '%' },
        "free"                => { name => 'free' },
    });

    return $self;
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    totalMemSize                    => { oid => '.1.3.6.1.4.1.637.61.1.9.29.2.1.1' },
    memAbsoluteUsage                => { oid => '.1.3.6.1.4.1.637.61.1.9.29.2.1.2' },
    eqptSlotActualType              => { oid => '.1.3.6.1.4.1.637.61.1.23.3.1.3' },
    eqptBoardInventorySerialNumber  => { oid => '.1.3.6.1.4.1.637.61.1.23.3.1.19' },
};

my $oid_asamSwmTotalSpaceOnFileDisk = '.1.3.6.1.4.1.637.61.1.24.1.6.0';
my $oid_asamSwmFreeSpaceOnFileDisk = '.1.3.6.1.4.1.637.61.1.24.1.7.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{totalMemSize}->{oid} },
                                                            { oid => $mapping->{memAbsoluteUsage}->{oid} },
                                                            { oid => $mapping->{eqptSlotActualType}->{oid} },
                                                            { oid => $mapping->{eqptBoardInventorySerialNumber}->{oid} },
                                                          ], return_type => 1, nothing_quit => 1);
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{memAbsoluteUsage}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        my $name = $result->{eqptBoardInventorySerialNumber} . '_' . $result->{eqptSlotActualType};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        $self->{memory}->{$name} = { display => $name, total => $result->{totalMemSize} * 1024 * 1024, used => $result->{memAbsoluteUsage} * 1024 * 1024 };
    }
    
    $snmp_result = $options{snmp}->get_leef(oids => [$oid_asamSwmTotalSpaceOnFileDisk, $oid_asamSwmFreeSpaceOnFileDisk]);
    if (defined($snmp_result->{$oid_asamSwmFreeSpaceOnFileDisk})) {
        my $name = 'SD Card';
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
        } else {
             $self->{memory}->{$name} = { display => $name, total => $snmp_result->{$oid_asamSwmTotalSpaceOnFileDisk}, 
                used => $snmp_result->{$oid_asamSwmTotalSpaceOnFileDisk} - $snmp_result->{$oid_asamSwmFreeSpaceOnFileDisk} };
        }
    }
    
    if (scalar(keys %{$self->{memory}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No memory found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--filter-name>

Filter memory name (can be a regexp).

=item B<--filter-project>

Filter project name (can be a regexp).

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
