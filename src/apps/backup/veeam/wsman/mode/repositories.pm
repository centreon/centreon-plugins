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

package apps::backup::veeam::wsman::mode::repositories;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::veeam::repositories;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::backup::veeam::wsman::mode::resources::types qw($repository_type $repository_status);
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{status}
    );
}

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
        { name => 'repositories', type => 3, cb_prefix_output => 'prefix_repository_output', cb_long_output => 'repository_long_output',
          indent_long_output => '    ', message_multiple => 'All repositories are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => 'not %{status} =~ /ordinal|maintenance/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'type' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'filter-name:s'     => { name => 'filter_name' },
        'exclude-name:s'    => { name => 'exclude_name' },
        'filter-type:s'     => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

        my $ps = centreon::common::powershell::veeam::repositories::get_powershell();
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

    my $result = $options{wsman}->execute_powershell(
        label => 'repositories',
        content => centreon::plugins::misc::powershell_encoded($ps)
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $result->{repositories}->{stdout}
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($result->{repositories}->{stdout}));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #  {"name": "repo 1", "type": 10, "status": 0, "totalSpace": 100000000, "freeSpace": 1000000 },
    #  {"name": "repo 2", "type": 11, "status": 0, "totalSpace": 250000000, "freeSpace": 1000000 }
    #]

    $self->{repositories} = {};
    foreach my $repo (@$decoded) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $repo->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne '' &&
            $repo->{name} =~ /$self->{option_results}->{exclude_name}/);

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $repo->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping repository '$repo->{name}'.", debug => 1);
            next;
        }

        my $type = defined($repository_type->{ $repo->{type} }) ? $repository_type->{ $repo->{type} } : 'unknown';
        $self->{repositories}->{ $repo->{name} } = {
            name => $repo->{name},
            type => $type,
            status => {
                name => $repo->{name},
                type => $type,
                status => defined($repository_status->{ $repo->{status} }) ? $repository_status->{ $repo->{status} } : 'unknown'
            },
            space => {
                name => $repo->{name},
                total => $repo->{totalSpace},
                free => $repo->{freeSpace},
                used => $repo->{totalSpace} - $repo->{freeSpace},
                prct_used => 100 - ($repo->{freeSpace} * 100 / $repo->{totalSpace}),
                prct_free => $repo->{freeSpace} * 100 / $repo->{totalSpace}
            }
        };
    }
}

1;

__END__

=head1 MODE

[EXPERIMENTAL] Monitor repositories.

=over 8


=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-name>

Filter repositories by name (can be a regexp).

=item B<--exclude-name>

Exclude repositories by name (regexp can be used).

=item B<--filter-type>

Filter repositories by type (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}, %{type}.

=item B<--critical-status>

Set critical threshold for status (Default: 'not %{status} =~ /ordinal|maintenance/i').
Can used special variables like: %{status}, %{name}, %{type}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct'.

=back

=cut
