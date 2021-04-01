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

package network::beeware::snmp::mode::reverseproxyusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rp', type => 1, cb_prefix_output => 'prefix_rp_output', message_multiple => 'All reverse proxy are ok' }
    ];
    
    $self->{maps_counters}->{rp} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'display' }, { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'cpu', nlabel => 'reverseproxy.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'CPU Usage : %.2f %%',
                perfdatas => [
                    { label => 'cpu', value => 'cpu', template => '%.2f', 
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'memory', nlabel => 'reverseproxy.memory.usage.bytes', set => {
                key_values => [ { name => 'memory' }, { name => 'display' } ],
                output_template => 'Memory Usage : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'memory', value => 'memory', template => '%s', 
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'nbchilds', nlabel => 'reverseproxy.child.count', set => {
                key_values => [ { name => 'nbchilds' }, { name => 'display' } ],
                output_template => 'Num childs : %s',
                perfdatas => [
                    { label => 'nbchilds', value => 'nbchilds', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} !~ /running/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_rp_output {
    my ($self, %options) = @_;
    
    return "Reverse proxy '" . $options{instance_value}->{display} . "' ";
}

my %mapping_running = (
    0 => 'down',
    1 => 'running',
);

my $oid_rp = '.1.3.6.1.4.1.30800.132';
my $oid_cpu_suffix = '31.57';
my $oid_memory_suffix = '117.57'; # MB
my $oid_nbchils_suffix = '119.57';
my $oid_running_suffix = '133.57'; # 1 seems running

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{rp} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_rp,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_rp\.(.*?)\.$oid_running_suffix$/ || defined($self->{rp}->{$1}));
        my $instance = $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $instance !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{rp}->{$instance} = { display => $instance, 
            cpu => $snmp_result->{$oid_rp . '.' . $instance . '.' . $oid_cpu_suffix},
            memory => $snmp_result->{$oid_rp . '.' . $instance . '.' . $oid_memory_suffix} * 1024 * 1024,
            nbchilds => $snmp_result->{$oid_rp . '.' . $instance . '.' . $oid_nbchils_suffix},
            status => defined($mapping_running{$snmp_result->{$oid_rp . '.' . $instance . '.' . $oid_running_suffix}}) ? 
                $mapping_running{$snmp_result->{$oid_rp . '.' . $instance . '.' . $oid_running_suffix}} : 'unknown',
        };
    }
    
    if (scalar(keys %{$self->{rp}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No reverse proxy found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check reverse proxy usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^cpu|memory$'

=item B<--filter-name>

Filter reverse proxy (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /running/i').
Can used special variables like: %{display}, %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'cpu', 'memory' (B), 'nbchilds'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu', 'memory' (B), 'nbchilds'.

=back

=cut
