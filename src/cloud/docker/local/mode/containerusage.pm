#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package cloud::docker::local::mode::containerusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_memory_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'container.memory.usage.bytes',
        unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
        value => int($self->{result_values}->{used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0,
        max => int($self->{result_values}->{total})
    );
}

sub custom_memory_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_memory_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        "memory total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_memory_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_memory_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_memory_usage'};
    # container is not running
    return -10 if ($self->{result_values}->{used} == 0);

    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub prefix_containers_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output',
          message_multiple => 'All containers are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];
    $self->{maps_counters}->{containers} = [
        { label => 'cpu', nlabel => 'container.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_prct' }, { name => 'name' } ],
                output_template => 'cpu usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'memory', nlabel => 'container.memory.usage.bytes', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'memory_total' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_memory_calc'),
                closure_custom_output => $self->can('custom_memory_output'),
                closure_custom_perfdata => $self->can('custom_memory_perfdata'),
                closure_custom_threshold_check => $self->can('custom_memory_threshold')
            }
        },
        { label => 'read-throughput', nlabel => 'container.disk.throughput.read.bytespersecond', set => {
                key_values => [ { name => 'read_throughput', per_second => 1 }, { name => 'name' } ],
                output_template => 'disk read throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'write-throughput', nlabel => 'container.disk.throughput.write.bytespersecond', set => {
                key_values => [ { name => 'write_throughput', per_second => 1 }, { name => 'name' } ],
                output_template => 'disk write throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'container.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'name' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'traffic-out',  nlabel => 'container.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'name' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub get_bytes {
    my ($self, %options) = @_;

    return undef if ($options{value} !~ /(\d+(?:\.\d+)?)\s*([a-zA-Z]+)/);
    my ($value, $unit) = ($1, $2);
    if ($unit =~ /KiB*/i) {
        $value = $value * 1024;
    } elsif ($unit =~ /MiB*/i) {
        $value = $value * 1024 * 1024;
    } elsif ($unit =~ /GiB*/i) {
        $value = $value * 1024 * 1024 * 1024;
    } elsif ($unit =~ /TiB*/i) {
        $value = $value * 1024 * 1024 * 1024 * 1024;
    } elsif ($unit =~ /KB*/i) {
        $value = $value * 1000;
    } elsif ($unit =~ /MB*/i) {
        $value = $value * 1000 * 1000;
    } elsif ($unit =~ /GB*/i) {
        $value = $value * 1000 * 1000 * 1000;
    } elsif ($unit =~ /TB*/i) {
        $value = $value * 1000 * 1000 * 1000 * 1000;
    }

    return $value;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'filter-id:s'   => { name => 'filter_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'docker stats',
        command_options => '-a --no-stream'
    );

    $self->{containers} = {};
    my @lines = split(/\n/, $stdout);
    # Header not needed
    # CONTAINER ID   NAME                 CPU %     MEM USAGE / LIMIT    MEM %     NET I/O           BLOCK I/O         PIDS
    # fe954c63d9ba   portainer            4.82%     72.14MiB / 7.79GiB   0.90%     387MB / 261MB     4.1kB / 0B        11

    shift(@lines);
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s{3,}(\S+)\s{3,}(\S+)\s{3,}(\S+)\s\/\s(\S+)\s{3,}\S+\s{3,}(\S+)\s\/\s(\S+)\s{3,}(\S+)\s\/\s(\S+).*$/);

        my ($id, $name, $cpu, $mem_usage, $mem_limit, $net_in, $net_out, $block_in, $block_out) = ($1, $2, $3, $4, $5, $6, $7, $8, $9);

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $id !~ /$self->{option_results}->{filter_id}/);

        $self->{containers}->{$id} = {
            name => $name,
            cpu_prct => substr($cpu, 0, -1),
            memory_usage => $self->get_bytes(value => $mem_usage),
            memory_total => $self->get_bytes(value => $mem_limit),
            read_throughput => $self->get_bytes(value => $block_in),
            write_throughput => $self->get_bytes(value => $block_out),
            traffic_in => $self->get_bytes(value => $net_in),
            traffic_out => $self->get_bytes(value => $net_out)
        };
    }

    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No container found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = 'docker_local_' . $self->{mode} . '_' . $self->{option_results}->{hostname} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')). '_' .
        (defined($self->{option_results}->{filter_id}) ? md5_hex($self->{option_results}->{filter_id}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check container usage.

Command used: docker stats -a --no-stream

Because values are scaled, statistics are not very
precise (except for CPU).

=over 8

=item B<--filter-name>

Filter by container name (can be a regexp).

=item B<--filter-id>

Filter by container ID (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu' (%), 'memory' (%), 'read-throughput',
'write-throughput', 'traffic-in', 'traffic-out'.

=back

=cut
