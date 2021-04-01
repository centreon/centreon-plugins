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

package network::huawei::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    if ($self->{result_values}->{total} > 0) {
        $self->{output}->perfdata_add(
            label => 'used', unit => 'B',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => $self->{result_values}->{used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
            min => 0, max => $self->{result_values}->{total}
        );
    } else {
        $self->{output}->perfdata_add(
            label => 'used', unit => '%',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => $self->{result_values}->{prct_used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0, max => 100
        );
    }
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg = 'Used: ' . $self->{result_values}->{prct_used} . '%';
    if ($self->{result_values}->{total} > 0) {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
        $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_total'} - $self->{result_values}->{free};

    if ($self->{result_values}->{total} > 0) {
        $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    } else {
        $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_used_prct'};
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok' }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'used_prct' }, { name => 'free' }, { name => 'total' } ],
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
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $oid_hwEntityMemUsage = '.1.3.6.1.4.1.2011.5.25.31.1.1.1.1.7'; # prct
my $oid_hwMemoryDevEntry = '.1.3.6.1.4.1.2011.6.3.5.1.1';
my $oid_hwResOccupancy = '.1.3.6.1.4.1.2011.6.3.17.1.1.3';
my $map_type = { 1 => 'memory', 2 => 'messageUnits', 3 => 'cpu' };

my $mapping = {
    hwMemoryDevSize     => { oid => '.1.3.6.1.4.1.2011.6.3.5.1.1.2' }, # B
    hwMemoryDevFree     => { oid => '.1.3.6.1.4.1.2011.6.3.5.1.1.3' }, # B
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{memory} = {};
    my $results = $options{snmp}->get_multiple_table(oids => [
        { oid => $oid_hwEntityMemUsage },
        { oid => $oid_hwMemoryDevEntry, end => $mapping->{hwMemoryDevFree}->{oid} },
        { oid => $oid_hwResOccupancy },
    ], nothing_quit => 1);

    my $num = 1;
    if (defined($results->{$oid_hwMemoryDevEntry}) && scalar(keys %{$results->{$oid_hwMemoryDevEntry}}) > 0) {
        foreach (keys %{$results->{$oid_hwMemoryDevEntry}}) {
            next if (!/^$mapping->{hwMemoryDevFree}->{oid}\.(.*)$/);
            my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results->{$oid_hwMemoryDevEntry}, instance => $1);
            $self->{memory}->{$num} = { display => $num, used_prct => -1, free => $result->{hwMemoryDevFree}, total => $result->{hwMemoryDevSize} };
            $num++;
        }
    } elsif (defined($results->{$oid_hwEntityMemUsage}) && scalar(keys %{$results->{$oid_hwEntityMemUsage}}) > 0) {
        foreach (keys %{$results->{$oid_hwEntityMemUsage}}) {
            $self->{memory}->{$num} = { display => $num, used_prct => $results->{$oid_hwEntityMemUsage}->{$_}, free => 0, total => 0 };
            $num++;
        }
    } else {
        foreach (keys %{$results->{$oid_hwResOccupancy}}) {
            /\.([0-9]*?)$/;
            next if (!defined($map_type->{$1}) || $map_type->{$1} ne 'memory');
            $self->{memory}->{$num} = { display => $num, used_prct => $results->{$oid_hwResOccupancy}->{$_}, free => 0, total => 0 };
            $num++;
        }
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=back

=cut
