#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::veeam::vone::restapi::mode::repositories;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_repository_state_numeric = {
    unknown => 0,
    ok => 1,
    inaccessible => 2,
    disconnected => 3,
    outOfDate => 4,
    warning => 5
};

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_status_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'repository.state.count',
        instances => $self->{result_values}->{name},
        value => $map_repository_state_numeric->{ $self->{result_values}->{state} },
        min => 0
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of repositories ';
}

sub repository_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking repository '%s' [type: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_repository_output {
    my ($self, %options) = @_;

    return sprintf(
        "repository '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'repositories', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_repository_output', cb_long_output => 'repository_long_output', indent_long_output => '    ', message_multiple => 'All repositories are ok',
            group => [
                { name => 'status', type => COUNTER_MULTIPLE_INSTANCE  },
                { name => 'space', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'repositories-detected', display_ok => 0, nlabel => 'repositories.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'repository.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'repository.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'repository.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'repository-status',
            type => COUNTER_KIND_TEXT,
            unknown_default => '%{state} =~ /unknown/',
            warning_default => '%{state} =~ /warning|outofdate/',
            critical_default => '%{state} =~ /inaccessible|disconnected/',
            set => {
                key_values => [
                    { name => 'state' }, { name => 'name' }, { name => 'type' }
                ],
                output_template => 'state: %s',
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
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
        'filter-uid:s'  => { name => 'filter_uid', default => '' },
        'filter-name:s' => { name => 'filter_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $repositories = $options{custom}->get_repositories();

    $self->{global} = { detected => 0 };
    $self->{repositories} = {};

    foreach my $repo (@{$repositories->{items}}) {
        next if is_excluded($repo->{repositoryUidInVbr}, $self->{option_results}->{filter_uid});
        next if is_excluded($repo->{name}, $self->{option_results}->{filter_name});

        $self->{repositories}->{ $repo->{name} } = {
            name => $repo->{name},
            type => $repo->{type},
            uid => $repo->{repositoryUidInVbr},
            space => {
                name => $repo->{name},
                total => $repo->{capacityBytes},
                free => $repo->{freeSpaceBytes},
                used => $repo->{capacityBytes} - $repo->{freeSpaceBytes},
                prct_used => 100 - ($repo->{freeSpaceBytes} * 100 / $repo->{capacityBytes}),
                prct_free => $repo->{freeSpaceBytes} * 100 / $repo->{capacityBytes}
            },
            status => {
                name => $repo->{name},
                type => $repo->{type},
                state => lc $repo->{state}
            }
        };
        $self->{global}->{detected}++;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['uid', 'name', 'type', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $repos = $self->manage_selection(custom => $options{custom});
    foreach (values %{$self->{repositories}}) {
        $self->{output}->add_disco_entry(uid => $_->{uid}, name => $_->{name}, type => $_->{type}, state => $_->{status}->{state});
    }
}

1;

__END__

=head1 MODE

Check repositories.

=over 8

=item B<--filter-uid>

Filter repositories by UID (can be a regexp).

=item B<--filter-name>

Filter repositories by name (can be a regexp).

=item B<--unknown-repository-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{state} =~ /unknown/').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--warning-repository-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /warning|outofdate/').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--critical-repository-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /inaccessible|disconnected/').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--warning-repositories-detected>

Threshold.

=item B<--critical-repositories-detected>

Threshold.

=item B<--warning-space-usage>

Threshold in bytes.

=item B<--critical-space-usage>

Threshold in bytes.

=item B<--warning-space-usage-free>

Threshold in bytes.

=item B<--critical-space-usage-free>

Threshold in bytes.

=item B<--warning-space-usage-prct>

Threshold in percentage.

=item B<--critical-space-usage-prct>

Threshold in percentage.

=back

=cut
