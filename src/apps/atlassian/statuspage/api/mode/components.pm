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

package apps::atlassian::statuspage::api::mode::components;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(is_excluded value_of);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_component_output {
    my ($self, %options) = @_;

    return sprintf(
        "Component '%s' %s",
        $options{instance_value}->{name},
        $options{instance_value}->{group} ne '' ? "[group: $options{instance_value}->{group}] " : ''
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'components',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_component_output',
            message_multiple => 'All components are ok'
        }
    ];

    $self->{maps_counters}->{components} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            unknown_default  => '%{status} =~ /unknown/',
            warning_default  => '%{status} =~ /degraded_performance|partial_outage/',
            critical_default => '%{status} =~ /major_outage/',
            set              => {
                key_values                     => [ { name => 'status' }, { name => 'name' }, { name => 'group' } ],
                output_template                => 'status: %s',
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
        'include-id:s'    => { name => 'include_id',    default => '' },
        'exclude-id:s'    => { name => 'exclude_id',    default => '' },
        'include-name:s'  => { name => 'include_name',  default => '' },
        'exclude-name:s'  => { name => 'exclude_name',  default => '' },
        'include-group:s' => { name => 'include_group', default => '' },
        'exclude-group:s' => { name => 'exclude_group', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $components = $options{custom}->get_components();

    my $groups = {};
    foreach my $component (@$components) {
        $groups->{ $component->{id} } = $component if ($component->{group});
    }

    $self->{components} = {};
    foreach my $component (@$components) {
        # A group status only mirrors its worst member.
        next if $component->{group};

        my $group = defined($component->{group_id}) ? value_of($groups->{ $component->{group_id} }, '->{name}') : '';
        next if is_excluded($component->{id}, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});
        next if is_excluded($component->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($group, $self->{option_results}->{include_group}, $self->{option_results}->{exclude_group}, output => $self->{output});

        $self->{components}->{ $component->{id} } = {
            id     => $component->{id},
            name   => $component->{name},
            group  => $group,
            # The authenticated API documents an empty status value.
            status => value_of($component, '->{status}') || 'unknown'
        };
    }

    $self->{output}->option_exit(short_msg => 'No component found.')
        if (!keys %{$self->{components}} && !$self->{output}->is_disco_show());
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'group', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $component (sort { $a->{group} cmp $b->{group} || $a->{name} cmp $b->{name} } values %{$self->{components}}) {
        $self->{output}->add_disco_entry(
            id     => $component->{id},
            name   => $component->{name},
            group  => $component->{group},
            status => $component->{status}
        );
    }
}

1;

__END__

=head1 MODE

Check the status of Atlassian Statuspage components.
This mode also supports service discovery (C<--disco-format>, C<--disco-show>).

=over 8

=item B<--include-id>

Filter components by ID (regular expression).

=item B<--exclude-id>

Exclude components by ID (regular expression).

=item B<--include-name>

Filter components by name (regular expression).

=item B<--exclude-name>

Exclude components by name (regular expression).

=item B<--include-group>

Filter components by group name (regular expression).

=item B<--exclude-group>

Exclude components by group name (regular expression).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: C<'%{status} =~ /unknown/'>).
You can use the following variables: C<%{status}>, C<%{name}>, C<%{group}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /degraded_performance|partial_outage/'>).
You can use the following variables: C<%{status}>, C<%{name}>, C<%{group}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /major_outage/'>).
You can use the following variables: C<%{status}>, C<%{name}>, C<%{group}>.

=back

=cut
