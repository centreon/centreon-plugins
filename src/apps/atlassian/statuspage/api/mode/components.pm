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
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'components',
            type             => COUNTER_TYPE_INSTANCE,
            prefix_output    => "Component '%{name}' ",
            message_multiple => 'All components are ok'
        }
    ];

    $self->{maps_counters}->{components} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{status} =~ /degraded_performance|partial_outage/',
            critical_default => '%{status} =~ /major_outage/',
            set              => {
                key_values                     => [ { name => 'status' }, { name => 'name' } ],
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
        'include-id:s'   => { name => 'include_id',   default => '' },
        'exclude-id:s'   => { name => 'exclude_id',   default => '' },
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $components = $options{custom}->get_components();

    $self->{components} = {};
    foreach my $component (@$components) {
        next if is_excluded($component->{id}, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});
        next if is_excluded($component->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        $self->{components}->{ $component->{id} } = {
            name   => $component->{name},
            status => $component->{status}
        };
    }

    $self->{output}->option_exit(short_msg => 'No component found.')
        if (!keys %{$self->{components}});
}

1;

__END__

=head1 MODE

Check the status of Atlassian Statuspage components.

=over 8

=item B<--include-id>

Filter components by ID (regular expression).

=item B<--exclude-id>

Exclude components by ID (regular expression).

=item B<--include-name>

Filter components by name (regular expression).

=item B<--exclude-name>

Exclude components by name (regular expression).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{name}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /degraded_performance|partial_outage/'>).
You can use the following variables: C<%{status}>, C<%{name}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /major_outage/'>).
You can use the following variables: C<%{status}>, C<%{name}>.

=back

=cut
