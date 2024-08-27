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

package apps::redis::sentinel::mode::redisclusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s [role: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{role}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "cluster '" . $options{instance} . "' ";
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "checking cluster '" . $options{instance} . "'";
}

sub prefix_instance_output {
    my ($self, %options) = @_;

    return "instance '" . $options{instance} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok', 
            group => [
                { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
                { name => 'stddev', type => 0, skipped_code => { -10 => 1 } },
                { name => 'instances', type => 1, display_long => 1, cb_prefix_output => 'prefix_instance_output', message_multiple => 'All redis instances are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'slaves-detected', nlabel => 'cluster.redis.slaves.detected.count', set => {
                key_values => [ { name => 'num_slaves' } ],
                output_template => 'detected slaves: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'redis-sdown', nlabel => 'cluster.redis.subjectively_down.count', set => {
                key_values => [ { name => 'sdown' } ],
                output_template => 'subjectively down instances: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'redis-odown', nlabel => 'cluster.redis.objectively_down.count', set => {
                key_values => [ { name => 'odown' } ],
                output_template => 'objectively down instances: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{stddev} = [
        { label => 'slave-repl-offset-stddev', nlabel => 'cluster.redis.slave_replication_offset.stddev.count', set => {
                key_values => [ { name => 'stddev_repl_offset' } ],
                output_template => 'slave replication offset standard deviation: %.2f',
                perfdatas => [
                    { template => '%.2f' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{instances} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /o_down|s_down|master_down|disconnected/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'role' }, 
                    { name => 'address' }, { name => 'port' }, 
                    { name => 'cluster_name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'redis-ping-ok-latency', nlabel => 'cluster.redis.ping_ok.latency.milliseconds', set => {
                key_values => [ { name => 'ping_ok_latency' } ],
                output_template => 'last ok ping: %s ms',
                perfdatas => [
                    { template => '%d', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-cluster-name:s' => { name => 'filter_cluster_name' }
    });

    return $self;
}

sub add_instance {
    my ($self, %options) = @_;

    my $key = $options{entry}->{ip} . ':' . $options{entry}->{port};
    $self->{clusters}->{ $options{cluster_name} }->{instances}->{$key} = {
        cluster_name => $options{cluster_name},
        address => $options{entry}->{ip},
        port => $options{entry}->{port},
        role => $options{entry}->{'role-reported'},
        status => $options{entry}->{flags},
        ping_ok_latency => $options{entry}->{'last-ok-ping-reply'},
        slave_repl_offset => $options{entry}->{'slave-repl-offset'}
    };
    $self->{clusters}->{ $options{cluster_name} }->{global}->{sdown}++
        if ($options{entry}->{flags} =~ /s_down/);
    $self->{clusters}->{ $options{cluster_name} }->{global}->{odown}++
        if ($options{entry}->{flags} =~ /o_down/);
}

sub stddev {
    my ($self, %options) = @_;

    my $total = 0;
    my $num = 0;
    foreach my $entry (values %{$self->{clusters}->{ $options{cluster_name} }->{instances}}) {
        next if (!defined($entry->{slave_repl_offset}));
        $total += $entry->{slave_repl_offset};
        $num++;
    }

    return if ($num <= 1);

    my $mean = $total / $num;
    $total = 0;
    foreach my $entry (values %{$self->{clusters}->{ $options{cluster_name} }->{instances}}) {
        next if (!defined($entry->{slave_repl_offset}));
        $total += ($mean - $entry->{slave_repl_offset}) ** 2;
    }
    $self->{clusters}->{ $options{cluster_name} }->{stddev} = { stddev_repl_offset => sqrt($total / $num) };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->command(command => 'sentinel masters');

    $self->{clusters} = {};
    foreach my $entry (@$results) {
        next if (defined($self->{option_results}->{filter_cluster_name}) && $self->{option_results}->{filter_cluster_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_cluster_name}/);

        $self->{clusters}->{ $entry->{name} } = {
            global => { num_slaves => $entry->{'num-slaves'}, odown => 0, sdown => 0 },
            instances => {}
        };
        $self->add_instance(cluster_name => $entry->{name}, entry => $entry);

        my $replicas = $options{custom}->command(command => 'sentinel replicas ' . $entry->{name});
        foreach (@$replicas) {
            $self->add_instance(cluster_name => $entry->{name}, entry => $_);
        }

        $self->stddev(cluster_name => $entry->{name});
    }

    if (scalar(keys %{$self->{clusters}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No redis cluster found.");
        $self->{output}->option_exit();
    }

    
}

1;

__END__

=head1 MODE

Check redis clusters informations.

=over 8

=item B<--filter-cluster-name>

Filter clusters by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{role}, %{address}, %{port}, %{cluster_name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{role}, %{address}, %{port}, %{cluster_name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /o_down|s_down|master_down|disconnected/i').
You can use the following variables: %{status}, %{role}, %{address}, %{port}, %{cluster_name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be:  'redis-ping-ok-latency', 'redis-sdown', 'redis-odown', 
'slave-repl-offset-stddev', 'slaves-detected'.

=back

=cut
