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

package apps::backup::veeam::vbr::restapi::mode::repositories;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded value_of/;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

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
                { name => 'status', type => COUNTER_MULTIPLE_INSTANCE },
                { name => 'space', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'repositories-detected', display_ok => 0, nlabel => 'repositories.detected.count', unknown_default => '@0', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'repository-status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{state} =~ /outofdate/i',
            critical_default => '%{state} =~ /offline/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'name' }, { name => 'type' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    my @space_values = map { { name => $_ } } qw/used free prct_used prct_free total name/;
    $self->{maps_counters}->{space} = [
        { label => 'space-usage', nlabel => 'repository.space.usage.bytes', set => {
                key_values => [ @space_values ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'repository.space.free.bytes', set => {
                key_values => [ { name => 'free' }, grep { $_->{name} ne 'free' } @space_values ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'repository.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, grep { $_->{name} ne 'prct_used' } @space_values ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
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
        'include-id:s'    => { name => 'include_id', default => '' },
        'exclude-id:s'    => { name => 'exclude_id', default => '' },
        'include-name:s'  => { name => 'include_name', default => '' },
        'exclude-name:s'  => { name => 'exclude_name', default => '' },
        'include-type:s'  => { name => 'include_type', default => '' },
        'exclude-type:s'  => { name => 'exclude_type', default => '' },
        'exclude-extents' => { name => 'exclude_extents' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $repositories = $options{custom}->get_repository_states(exclude_extents => $self->{option_results}->{exclude_extents});

    $self->{global} = { detected => 0 };
    $self->{repositories} = {};

    foreach my $repo (@$repositories) {
        next if is_excluded($repo->{id}, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output})
            || is_excluded($repo->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
            || is_excluded($repo->{type}, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output});

        my $type = value_of($repo, '->{type}', 'Unknown');
        my $state = !value_of($repo, '->{isOnline}', 0) ? 'offline' : value_of($repo, '->{isOutOfDate}', 0) ? 'outOfDate' : 'online';
        $self->{repositories}->{ $repo->{id} } = {
            id => $repo->{id},
            name => $repo->{name},
            type => $type,
            host_name => value_of($repo, '->{hostName}', '-'),
            path => value_of($repo, '->{path}', '-'),
            status => { name => $repo->{name}, type => $type, state => $state },
            space => {}
        };

        # Capacity is not always reported, for example on some object storage repositories
        my $capacity = value_of($repo, '->{capacityGB}', 0);
        if ($capacity > 0) {
            my $total = int($capacity * 1024 * 1024 * 1024);
            my $free = int(value_of($repo, '->{freeGB}', 0) * 1024 * 1024 * 1024);
            $self->{repositories}->{ $repo->{id} }->{space} = {
                name => $repo->{name},
                total => $total,
                free => $free,
                used => $total - $free,
                prct_free => $free * 100 / $total,
                prct_used => 100 - ($free * 100 / $total)
            };
        }

        $self->{global}->{detected}++;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'type', 'host_name', 'path']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $repo (sort { $a->{name} cmp $b->{name} } values %{$self->{repositories}}) {
        $self->{output}->add_disco_entry(
            id => $repo->{id},
            name => $repo->{name},
            type => $repo->{type},
            host_name => $repo->{host_name},
            path => $repo->{path}
        );
    }
}

1;

__END__

=head1 MODE

Check repositories state and space usage.

=over 8

=item B<--include-id>

Filter repositories by ID (can be a regexp).

=item B<--exclude-id>

Exclude repositories by ID (can be a regexp).

=item B<--include-name>

Filter repositories by name (can be a regexp).

=item B<--exclude-name>

Exclude repositories by name (can be a regexp).

=item B<--include-type>

Filter repositories by type (can be a regexp). Example: C<WinLocal>, C<LinuxHardened>, C<AmazonS3>.

=item B<--exclude-type>

Exclude repositories by type (can be a regexp).

=item B<--exclude-extents>

Do not return the extents of scale-out backup repositories.

=item B<--warning-repository-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /outofdate/i').
You can use the following variables: %{state} (C<online>, C<offline> or C<outOfDate>), %{name}, %{type}

=item B<--critical-repository-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /offline/i').
You can use the following variables: %{state} (C<online>, C<offline> or C<outOfDate>), %{name}, %{type}

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
