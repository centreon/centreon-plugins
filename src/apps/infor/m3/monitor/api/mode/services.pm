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

package apps::infor::m3::monitor::api::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [description: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{description}
    );
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok' }
    ];

    $self->{maps_counters}->{services} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /up/',
            set => {
                key_values => [
                    { name => 'description' }, { name => 'status' }, { name => 'name' }
                ],
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
        method => 'GET',
        url_path => '/monitor',
        get_param => ['category=services'],
        force_array => ['services', 'service']
    );

    foreach my $entry (@{$result->{category}->{service}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_name}/);
        $self->{services}->{$entry->{name}} = {
            name => $entry->{name},
            description => $entry->{description},
            status => (defined($entry->{'port-status'})) ? $entry->{'port-status'} : $entry->{'thread-status'}
        }
    }

    if (scalar(keys %{$self->{services}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No services found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check service status.

=over 8

=item B<--filter-name>

Filter by name.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{name}, %{description}.

=item B<--critical-status>

Set critical threshold for status (Default: "%{status} !~ /up/").
Can use special variables like: %{status}, %{name}, %{description}.

=back

=cut