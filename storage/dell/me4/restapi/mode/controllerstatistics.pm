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

package storage::dell::me4::restapi::mode::controllerstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'controllers', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All controllers statistics are ok' }
    ];

    $self->{maps_counters}->{controllers} = [
        { label => 'data-read', nlabel => 'controller.data.read.bytespersecond', set => {
                key_values => [ { name => 'data-read-numeric', per_second => 1 }, { name => 'display' } ],
                output_template => 'Data Read: %s%s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'data-written', nlabel => 'controller.data.written.bytespersecond', set => {
                key_values => [ { name => 'data-written-numeric', per_second => 1 }, { name => 'display' } ],
                output_template => 'Data Written: %s%s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'reads', nlabel => 'controller.reads.count', set => {
                key_values => [ { name => 'number-of-reads', per_second => 1 }, { name => 'display' } ],
                output_template => 'Reads: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'writes', nlabel => 'controller.writes.count', set => {
                key_values => [ { name => 'number-of-writes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Writes: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'data-transfer', nlabel => 'controller.data.transfer.bytespersecond', set => {
                key_values => [ { name => 'bytes-per-second-numeric'}, { name => 'display' } ],
                output_template => 'Data Transfer: %s%s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'iops', nlabel => 'controller.iops.ops', set => {
                key_values => [ { name => 'iops'}, { name => 'display' } ],
                output_template => 'IOPS: %d ops',
                perfdatas => [
                    { template => '%d', min => 0, unit => 'ops', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'forwarded-cmds', nlabel => 'controller.commands.forwarded.count', set => {
                key_values => [ { name => 'num-forwarded-cmds'}, { name => 'display' } ],
                output_template => 'Forwarded Commands: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-cache-used', nlabel => 'controller.cache.write.usage.percentage', set => {
                key_values => [ { name => 'write-cache-used'}, { name => 'display' } ],
                output_template => 'Cache Write Usage: %s%%',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-cache-hits', nlabel => 'controller.cache.write.hits.count', set => {
                key_values => [ { name => 'write-cache-hits', per_second => 1 }, { name => 'display' } ],
                output_template => 'Cache Write Hits: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-cache-misses', nlabel => 'controller.cache.write.misses.count', set => {
                key_values => [ { name => 'write-cache-misses', per_second => 1 }, { name => 'display' } ],
                output_template => 'Cache Write Misses: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-cache-hits', nlabel => 'controller.cache.read.hits.count', set => {
                key_values => [ { name => 'read-cache-hits', per_second => 1 }, { name => 'display' } ],
                output_template => 'Cache Read Hits: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-cache-misses', nlabel => 'controller.cache.read.misses.count', set => {
                key_values => [ { name => 'read-cache-misses', per_second => 1 }, { name => 'display' } ],
                output_template => 'Cache Read Misses: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cpu-utilization', nlabel => 'controller.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu-load'}, { name => 'display' } ],
                output_template => 'CPU Utilization: %.2f%%',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Controller '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(method => 'GET', url_path => '/api/show/controller-statistics');

    $self->{controllers} = {};

    foreach my $controller (@{$results->{'controller-statistics'}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $controller->{'durable-id'} !~ /$self->{option_results}->{filter_name}/);
        
        $self->{controllers}->{$controller->{'durable-id'}} = { display => $controller->{'durable-id'}, %{$controller} };
    }
    
    if (scalar(keys %{$self->{controllers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No controllers found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "dell_me4_" . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

}

1;

__END__

=head1 MODE

Check controllers statistics.

=over 8

=item B<--filter-name>

Filter controller name (Can be a regexp).

=item B<--warning-instance-*>

Threshold warning.
Can be: 'controller-data-read-bytespersecond', 'controller-data-written-bytespersecond',
'controller-reads-count', 'controller-writes-count',
'controller-data-transfer-bytespersecond', 'controller-iops-ops',
'controller-commands-forwarded-count',
'controller-cache-write-usage-percentage', 'controller-cache-write-hits-count',
'controller-cache-write-misses-count', 'controller-cache-read-hits-count',
'controller-cache-read-misses-count', 'controller-cpu-utilization-percentage'.

=item B<--critical-instance-*>

Threshold critical.
Can be: 'controller-data-read-bytespersecond', 'controller-data-written-bytespersecond',
'controller-reads-count', 'controller-writes-count',
'controller-data-transfer-bytespersecond', 'controller-iops-ops',
'controller-commands-forwarded-count',
'controller-cache-write-usage-percentage', 'controller-cache-write-hits-count',
'controller-cache-write-misses-count', 'controller-cache-read-hits-count',
'controller-cache-read-misses-count', 'controller-cpu-utilization-percentage'.

=back

=cut
