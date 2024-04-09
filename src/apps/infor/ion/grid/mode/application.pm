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

package apps::infor::ion::grid::mode::application;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "state is '%s' [online: %s] [started: %s]",
        $self->{result_values}->{state},
        $self->{result_values}->{online},
        $self->{result_values}->{started}
    );
}

sub prefix_application_output {
    my ($self, %options) = @_;

    return sprintf(
        "Application '%s' [description: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{description}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total applications ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name             => 'global',
          type             => 0,
          cb_prefix_output => 'prefix_global_output' },
        { name             => 'applications',
          type             => 1,
          cb_prefix_output => 'prefix_application_output',
          message_multiple => 'All applications are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label  => 'total',
          nlabel => 'ion.grid.applications.total.count',
          set    => {
              key_values      => [{ name => 'total' }],
              output_template => "Total : %s",
              perfdatas       => [{ template => '%d', min => 0 }] }
        }
    ];

    $self->{maps_counters}->{applications} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{online} =~ /true/ && %{state} !~ /^(OK)/i',
            set              => {
                key_values                     => [
                    { name => 'state' }, { name => 'online' }, { name => 'name' },
                    { name => 'description' }, { name => 'started' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method   => 'GET',
        url_path => '/grid/rest/applications'
    );

    foreach my $entry (@{$result}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
                 && $entry->{name} !~ /$self->{option_results}->{filter_name}/);
        $self->{applications}->{$entry->{name}} = {
            name        => $entry->{name},
            description => $entry->{description},
            online      => ($entry->{online}) ? "true" : "false",
            started     => ($entry->{started}) ? "true" : "false",
            state       => $entry->{globalState}->{stateText}
        }
    }

    if (scalar(keys %{$self->{applications}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No applications found");
        $self->{output}->option_exit();
    }

    $self->{global}->{total} = scalar(keys %{$self->{applications}});
}

1;

__END__

=head1 MODE

Monitor the status of the application.

=over 8

=item B<--filter-name>

Define which applications should be monitored based on their names. This option will be treated as a regular expression.
Example: --filter-name='^application1$'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
The condition can be written using special variables like %{state}, %{online}, %{started},
%{name} or %{description}. Regular expressions are supported.
Typical syntax: --warning-status='%{state} ne "OK"'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{online} =~ /true/ && %{state} !~ /^(OK)/i').
The condition can be written using special variables like %{state}, %{online}, %{started},
%{name} or %{description}. Regular expressions are supported.
Typical syntax: --critical-status='%{started} ne "true"'

=item B<--warning-total>

Define the warning threshold for the total number of applications.

=item B<--critical-total>

Define the critical threshold for the total number of applications.

=back

=cut