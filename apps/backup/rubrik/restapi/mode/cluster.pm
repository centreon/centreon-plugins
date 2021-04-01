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

package apps::backup::rubrik::restapi::mode::cluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use POSIX;
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return  'status: ' . $self->{result_values}->{status};
}

sub prefix_cluster_output {
    my ($self, %options) = @_;
    
    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'clusters', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{clusters} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /ok/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'read', nlabel => 'cluster.io.read.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'read' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'cluster.io.write.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'write' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'cluster.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops' } ],
                output_template => 'read iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'cluster.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' } ],
                output_template => 'write iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'cluster-id:s' => { name => 'cluster_id', default => 'me' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{cluster_id} = 'me' if ($self->{option_results}->{cluster_id} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'rubrik_' . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        md5_hex($self->{option_results}->{cluster_id});

    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    $last_timestamp = time() - (5 * 60) if (!defined($last_timestamp));
    my $timespan = POSIX::ceil((time() - $last_timestamp) / 60);
    $timespan = 1 if ($timespan <= 0);

    my $name = $options{custom}->request_api(endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/name');
    my $status = $options{custom}->request_api(endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/system_status');
    my $io_stats = $options{custom}->request_api(
        endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/io_stats',
        get_param => ['range=-' . $timespan . 'min']
    );

    $self->{clusters} = {
        $name => {
            name => $name,
            status => $status->{status}
        }
    };

    foreach my $entry ((
        ['ioThroughput', 'readBytePerSecond', 'read'], ['ioThroughput', 'writeBytePerSecond', 'write'],
        ['iops', 'readsPerSecond', 'read_iops'], ['iops', 'writesPerSecond', 'write_iops']
    )) {
        my $count = 0;
        foreach (@{$io_stats->{ $entry->[0] }->{ $entry->[1] }}) {
            $self->{clusters}->{$name}->{ $entry->[2] } = 0 
                if (!defined($self->{clusters}->{$name}->{ $entry->[2] }));
            $self->{clusters}->{$name}->{ $entry->[2] } += $_->{stat};
            $count++;
        }
        $self->{clusters}->{$name}->{ $entry->[2] } = int($self->{clusters}->{$name}->{ $entry->[2] } / $count) if ($count > 0);
    }
}

1;

__END__

=head1 MODE

Check cluster.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--cluster-id>

Which cluster to check (Default: 'me').

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /ok/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'read' (B/s), 'write' (B/s), 'read-iops', 'write-iops'.

=back

=cut
