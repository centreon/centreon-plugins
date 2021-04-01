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

package storage::buffalo::terastation::snmp::mode::arrayusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

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
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_nasArrayUsed'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_nasArrayCapacity'} * 1024 * 1024 * 1024;
    $self->{result_values}->{used} = int($self->{result_values}->{prct_used} * $self->{result_values}->{total} / 100);
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'array', type => 1, cb_prefix_output => 'prefix_array_output', message_multiple => 'All arrays are ok' }
    ];
    
    $self->{maps_counters}->{array} = [
        { label => 'usage', nlabel => 'array.space.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'nasArrayCapacity' }, { name => 'nasArrayUsed' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'used', value => 'used', template => '%s',
                      unit => 'B', min => 0, max => 'total', cast_int => 1 },
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
        "filter-name:s" => { name => 'filter_name' },
    });

    return $self;
}

sub prefix_array_output {
    my ($self, %options) = @_;
    
    return "Array '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    nasArrayCapacity    => { oid => '.1.3.6.1.4.1.5227.27.1.3.1.3' }, # in GB
    nasArrayUsed        => { oid => '.1.3.6.1.4.1.5227.27.1.3.1.4' }, # in %
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_nasArrayEntry = '.1.3.6.1.4.1.5227.27.1.3.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_nasArrayEntry,
        start => $mapping->{nasArrayCapacity}->{oid},
        end => $mapping->{nasArrayUsed}->{oid},
        nothing_quit => 1
    );

    $self->{array} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{nasArrayCapacity}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $instance !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': no matching array name.", debug => 1);
            next;
        }
        if ($result->{nasArrayUsed} == -1) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': array not used.", debug => 1);
            next;
        }

        $self->{array}->{$instance} = { display => $instance, %$result };
    }
    
    if (scalar(keys %{$self->{array}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No array found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check array usages.

=over 8

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=back

=cut
