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

package network::citrix::sdx::snmp::mode::xenusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'memory_used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'memory_free';
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
    my $msg = sprintf("Memory Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_mem_total'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_mem_free'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'xen', type => 1, cb_prefix_output => 'prefix_xen_output', message_multiple => 'All xen hypervisors are ok' }
    ];
    
    $self->{maps_counters}->{xen} = [
        { label => 'memory-usage', set => {
                key_values => [ { name => 'display' }, { name => 'mem_free' }, { name => 'mem_total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'cpu-usage', set => {
                key_values => [ { name => 'xenCpuUsage' }, { name => 'display' } ],
                output_template => 'CPU Usage : %.2f %%', output_error_template => "CPU Usage : %s",
                perfdatas => [
                    { label => 'cpu_usage', value => 'xenCpuUsage', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
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

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    return "Xen '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    xenHostname     => { oid => '.1.3.6.1.4.1.5951.6.3.1.1.3' },
    xenCpuUsage     => { oid => '.1.3.6.1.4.1.5951.6.3.1.1.8' },
    xenMemoryTotal  => { oid => '.1.3.6.1.4.1.5951.6.3.1.1.9' },
    xenMemoryFree   => { oid => '.1.3.6.1.4.1.5951.6.3.1.1.10' },
};

my $oid_xenEntry = '.1.3.6.1.4.1.5951.6.3.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{xen} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_xenEntry,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{xenHostname}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{xenHostname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{xenHostname} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{xen}->{$instance} = { 
            display => $result->{xenHostname},
            mem_total => $result->{xenMemoryTotal} * 1024 * 1024,
            mem_free => $result->{xenMemoryFree} * 1024 * 1024,
            %$result
        };
    }
    
    if (scalar(keys %{$self->{xen}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No xen hypervisor found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check xen hypervisors.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory-usage$'

=item B<--filter-name>

Filter xen name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'cpu-usage', 'memory-usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu-usage', 'memory-usage'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
