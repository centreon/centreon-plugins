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

package apps::proxmox::ve::restapi::mode::storageusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
}

sub custom_storage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'storage.space.usage.bytes',
        unit => 'B',
        instances => $self->{result_values}->{display},
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_storage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used},
        threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_storage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        "space total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_storage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_storage_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_storage_usage'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};

    return -10 if ($self->{result_values}->{total} <= 0);

    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};

    return 0;
}

sub prefix_storages_output {
    my ($self, %options) = @_;

    return "Storage '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storages', type => 1, cb_prefix_output => 'prefix_storages_output',
          message_multiple => 'All storages are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];

    $self->{maps_counters}->{storages} = [
        { label => 'storage-status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'storage', set => {
                key_values => [ { name => 'storage_usage' }, { name => 'storage_total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_storage_calc'),
                closure_custom_output => $self->can('custom_storage_output'),
                closure_custom_perfdata => $self->can('custom_storage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_storage_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'storage-id:s'   => { name => 'storage_id' },
        'storage-name:s' => { name => 'storage_name' },
        'filter-name:s'  => { name => 'filter_name' },
        'use-name'       => { name => 'use_name' },
        'node-id:s'      => { name => 'node_id' },
        'node-name:s'    => { name => 'node_name' }
    });

    $self->{statefile_cache_storages} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache_storages}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->api_get_storages(
        storage_id => $self->{option_results}->{storage_id},
        storage_name => $self->{option_results}->{storage_name},
        node_id => $self->{option_results}->{node_id},
        node_name => $self->{option_results}->{node_name},
        statefile => $self->{statefile_cache_storages}
    );

    $self->{storages} = {};
    foreach my $storage_id (keys %{$result}) {
        next if (!defined($result->{$storage_id}->{Stats}));

        my $name = $result->{$storage_id}->{Name};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{storages}->{$storage_id} = {
            display => defined($self->{option_results}->{use_name}) ? $name : $storage_id,
            name => $name,
            state => $result->{$storage_id}->{State},
            storage_usage => $result->{$storage_id}->{Stats}->{used},
            storage_total => $result->{$storage_id}->{Stats}->{total}
        };
    }

    if (scalar(keys %{$self->{storages}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage found.");
        $self->{output}->option_exit();
    }

    my $hostnames = $options{custom}->get_hostnames();
    $self->{cache_name} = 'proxmox_' . $self->{mode} . '_' . $hostnames . '_' . $options{custom}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{storage_id}) ? $self->{option_results}->{storage_id} : '') . '_' .
            (defined($self->{option_results}->{storage_name}) ? $self->{option_results}->{storage_name} : '') . '_' .
            (defined($self->{option_results}->{node_id}) ? $self->{option_results}->{node_id} : '') . '_' .
            (defined($self->{option_results}->{node_name}) ? $self->{option_results}->{node_name} : '')
        );
        
}

1;

__END__

=head1 MODE

Check storage usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^storage-status$'

=item B<--storage-id>

Exact storage ID.

=item B<--storage-name>

Exact storage name (if multiple names: names separated by ':').

=item B<--use-name>

Use storage name for perfdata and display.

=item B<--filter-name>

Filter by storage name (can be a regexp).

=item B<--node-id>

Exact node ID.

=item B<--node-name>

Exact node name.

=item B<--warning-storage-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{name}, %{state}.

=item B<--critical-storage-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{name}, %{state}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'storage' (%).

=back

=cut
