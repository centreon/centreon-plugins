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

package storage::emc::isilon::snmp::mode::clusterusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status: ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
     
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'ifs_used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'ifs_free';
        $value_perf = $self->{result_values}->{free};
    }
   
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
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
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("IFS Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

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
        { name => 'cluster', type => 0, cb_prefix_output => 'prefix_cluster_output', message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{cluster} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'health', set => {
                key_values => [ { name => 'health' } ],
                output_template => 'Node health: %.2f%%',
                perfdatas => [
                    { label => 'health', value => 'health', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'ifs-usage', set => {
                key_values => [ { name => 'used' }, { name => 'total' } ],
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
        'warning-status:s'    => { name => 'warning_status', default => '%{status} =~ /attn/' },
        'critical-status:s'   => { name => 'critical_status', default => '%{status} =~ /down|invalid/' },
        'units:s'             => { name => 'units', default => '%' },
        'free'                => { name => 'free' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_cluster_output {
    my ($self, %options) = @_;
    
    return "Cluster ";
}

my %mapping_health = (
    0 => 'ok',
    1 => 'attn',
    2 => 'down',
    3 => 'invalid',
);

my $mapping = {
    clusterHealth       => { oid => '.1.3.6.1.4.1.12124.1.1.2', map => \%mapping_health },
    nodeCount           => { oid => '.1.3.6.1.4.1.12124.1.1.4' },
    onlineNodes         => { oid => '.1.3.6.1.4.1.12124.1.1.6' },
    ifsTotalBytes       => { oid => '.1.3.6.1.4.1.12124.1.3.1' },
    ifsUsedBytes        => { oid => '.1.3.6.1.4.1.12124.1.3.2' },
    ifsAvailableBytes   => { oid => '.1.3.6.1.4.1.12124.1.3.3' },
};

my $oid_clusterStatus = '.1.3.6.1.4.1.12124.1.1';
my $oid_ifsFilesystem = '.1.3.6.1.4.1.12124.1.3';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{results} = $options{snmp}->get_multiple_table(oids => [{ oid => $oid_clusterStatus },
                                                                   { oid => $oid_ifsFilesystem },
                                                         ],
                                                         nothing_quit => 1, return_type => 1);
    
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => '0');
    
    my @online_nodes = split(/,/, $result->{onlineNodes});
    my $health = scalar(@online_nodes) * 100 / $result->{nodeCount};
    
    $self->{cluster} = { 
        status => $result->{clusterHealth},
        health => $health,
        total => $result->{ifsTotalBytes},
        used => $result->{ifsUsedBytes},
    };
}

1;

__END__

=head1 MODE

Check cluster usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /attn/).
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down|invalid/').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'ifs-usage', 'health'.

=item B<--critical-*>

Threshold critical.
Can be: 'ifs-usage', 'health'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
