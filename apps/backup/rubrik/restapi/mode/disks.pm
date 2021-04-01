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

package apps::backup::rubrik::restapi::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "checking cluster '" . $options{instance_value}->{name} . "'";
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "cluster '" . $options{instance_value}->{name} . "' ";
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "disk '" . $options{instance_value}->{id} . "' ";
}

sub prefix_global_cluster_output {
    my ($self, %options) = @_;

    return 'disks ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok',
            group => [
                { name => 'cluster', type => 0, cb_prefix_output => 'prefix_global_cluster_output' },
                { name => 'disks', type => 1, display_long => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'disks are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-disks-total', nlabel => 'cluster.disks.total.count', display_ok => 0, set => {
                key_values => [ { name => 'disks_total' } ],
                output_template => 'total %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cluster-disks-active', nlabel => 'cluster.disks.active.count', display_ok => 0, set => {
                key_values => [ { name => 'disks_active' }, { name => 'disks_total' } ],
                output_template => 'active %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'disks_total', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{disks} = [
        { label => 'disk-status', type => 2, critical_default => '%{status} !~ /active/i', set => {
                key_values => [ { name => 'status' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'cluster-id:s'     => { name => 'cluster_id', default => 'me' },
        'filter-disk-id:s' => { name => 'filter_disk_id' }
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

    my $name = $options{custom}->request_api(endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/name');
    my $disks = $options{custom}->request_api(endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/disk');

    $self->{clusters} = {
        $name => {
            name => $name,
            cluster => {
                disks_total => 0,
                disks_active => 0
            },
            disks => {}
        }
    };
    foreach (@{$disks->{data}}) {
        my $id = $_->{nodeId} . ':' . $_->{id};
        next if (defined($self->{option_results}->{filter_disk_id}) && $self->{option_results}->{filter_disk_id} ne '' &&
            $id !~ /$self->{option_results}->{filter_disk_id}/);

        $self->{clusters}->{$name}->{disks}->{$id} = {
            id => $id,
            status => lc($_->{status})
        };
        $self->{clusters}->{$name}->{cluster}->{ 'disks_' . lc($_->{status}) }++
            if (defined($self->{clusters}->{$name}->{cluster}->{ 'disks_' . lc($_->{status}) }));
        $self->{clusters}->{$name}->{cluster}->{disks_total}++;
    }
}

1;

__END__

=head1 MODE

Check cluster disks.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='disk-status'

=item B<--cluster-id>

Which cluster to check (Default: 'me').

=item B<--filter-disk-id>

Filter disks by disk id (can be a regexp).

=item B<--unknown-disks-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{id}

=item B<--warning-disk-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{id}

=item B<--critical-disk-status>

Set critical threshold for status (Default: '%{status} !~ /active/i').
Can used special variables like: %{status}, %{id}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cluster-disks-total', 'cluster-disks-active'.

=back

=cut
