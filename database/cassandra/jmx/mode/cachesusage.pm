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

package database::cassandra::jmx::mode::cachesusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ccache', type => 1, cb_prefix_output => 'prefix_ccache_output', message_multiple => 'All caches are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{ccache} = [
        { label => 'used', nlabel => 'ccache.utilization.percentage', set => {
                key_values => [ { name => 'Capacity_Value' }, { name => 'Size_Value' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'used', value => 'prct_used', template => '%.2f', 
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'hits', nlabel => 'ccache.hits.percentage', set => {
                key_values => [ { name => 'Requests_Count', diff => 1 }, { name => 'Hits_Count', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_hits_calc'),
                output_template => 'Hits = %.2f %%', output_use => 'hits_prct', threshold_use => 'hits_prct',
                perfdatas => [
                    { label => 'hits', value => 'hits_prct', template => '%.2f', min => 0, max => 100, 
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
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

    return -10 if ($options{new_datas}->{$self->{instance} . '_Capacity_Value'} <= 0);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_Capacity_Value'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_Size_Value'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub custom_hits_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $delta_value = $options{new_datas}->{$self->{instance} . '_Hits_Count'} - $options{old_datas}->{$self->{instance} . '_Hits_Count'};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_Requests_Count'} - $options{old_datas}->{$self->{instance} . '_Requests_Count'};

    $self->{result_values}->{hits_prct} = 0;
    if ($delta_total > 0) {
        $self->{result_values}->{hits_prct} = $delta_value * 100 / $delta_total;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"       => { name => 'filter_name' },
    });
    
    return $self;
}

sub prefix_ccache_output {
    my ($self, %options) = @_;
    
    return "Cache '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{ccache} = {};
    $self->{request} = [
         { mbean => 'org.apache.cassandra.metrics:name=Requests,scope=*,type=Cache', attributes => [ { name => 'Count' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=Hits,scope=*,type=Cache', attributes => [ { name => 'Count' } ] },
         { mbean => 'org.apache.cassandra.metrics:name=Capacity,scope=*,type=Cache', attributes => [ { name => 'Value' } ] }, # bytes
         { mbean => 'org.apache.cassandra.metrics:name=Size,scope=*,type=Cache', attributes => [ { name => 'Value' } ] }, # bytes
    ];
    
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);
    foreach my $mbean (keys %{$result}) {
        $mbean =~ /scope=(.*?)(?:,|$)/;
        my $scope = $1;
        $mbean =~ /name=(.*?)(?:,|$)/;
        my $name = $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $scope !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $scope . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ccache}->{$scope} = { display => $scope } if (!defined($self->{ccache}->{$scope}));
        foreach (keys %{$result->{$mbean}}) {
            $self->{ccache}->{$scope}->{$name . '_' . $_} = $result->{$mbean}->{$_};
        }
    }
    
    if (scalar(keys %{$self->{ccache}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No cache found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "cassandra_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check cache usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='latency'

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'used' (%), 'hits' (%).

=back

=cut
