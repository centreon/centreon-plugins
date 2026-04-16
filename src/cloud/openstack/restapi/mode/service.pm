#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::mode::service;

use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/flatten_arrays/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'service-url:s@'                  => { name => 'service_url' },
        'expected-data:s'                 => { name => 'expected_data', default => 'auto' },
        'endpoint-suffix:s'               => { name => 'endpoint_suffix', default => 'auto' },
        cloud::openstack::restapi::custom::api::_service_filters_options(type => 'service'),
    });

    return $self;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $interface = $self->{result_values}->{interface} =~ /^http/ ?
                        $self->{result_values}->{interface} :
                        $self->{result_values}->{interface}.' interface';
    sprintf('Service [%s] [%s] responded %swith HTTP %s on %s',
        $self->{result_values}->{name},
        $self->{result_values}->{type},
        $self->{result_values}->{valid_content} ? '' : 'invalid content ',
        $self->{result_values}->{http_status},
        $interface);
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, },
        { name => 'services', type => 1, message_multiple => 'All services are ok' }
    ];
    $self->{maps_counters}->{global} = [
        {  label => 'count', nlabel => 'endpoints.count.total',
           critical_default => '1:',
           set => {
                key_values => [ { name => 'count' } ],
                output_template => '%d endpoints responded',
                perfdatas => [
                    { label => 'total_endpoints', value => 'count', template => '%d',
                      min => 0 }
                ]
           }
        } ];

    $self->{maps_counters}->{services} = [
        {  label => 'status', type => 2, critical_default => '%{http_status} !~ /^(200|300)$/ || %{valid_content} != 1',
           set => {
                key_values => [ { name => 'name' }, { name => 'type'},
                                { name => 'http_status' }, { name => 'http_status_message'},
                                { name => 'valid_content' }, { name => 'interface' },
                                { name => 'region' } ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_status_output')
           }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{service_url} = flatten_arrays($self->{option_results}->{service_url});
    $self->{$_} = $self->{option_results}->{$_} foreach qw/endpoint_suffix expected_data/;
}

sub manage_selection {
    my ($self, %options) = @_;
    $options{custom}->service_check_filters(type => 'service');

    #    $options{custom}->filters_check_options();

    my ($services, $count);

    # Retry to handle token expiration
    RETRY: for my $retry (1..2) {
        $count = 0;
        $self->{services} = {};
        # Don't use the Keystone cache on the second try to force reauthentication
        $services = $options{custom}->keystone_authent( dont_read_cache => $retry > 1 );
        $options{custom}->other_services_check_options( keystone_services => $services->{services} );

        if (@{$self->{service_url}}) {
            # If user sets specifics URLs we set default type/name if they are not already defined and
            # we don't use use the Keystone service list
            my $type = $options{custom}->{include_service_type}->[0] // 'service';
            my $name = $options{custom}->{include_service_name}->[0] // 'N/A';

            foreach my $endpoint_url (@{$self->{service_url}}) {
                my $result = $options{custom}->ping_service(type => $type,
                                                            service_url => $endpoint_url,
                                                            inscure => $options{custom}->{insecure_service},
                                                            endpoint_suffix => $self->{endpoint_suffix},
                                                            expected_data => $self->{expected_data});

                # Retry one time if unauthorized
                next RETRY if $result->{http_status} == 401 && $retry == 1;

                $self->{services}->{$count++} = { type => $type,
                                                  name => $name,
                                                  interface => $endpoint_url,
                                                  region => '-',
                                                  %$result }
            }
        } else {
            # Using the cached Keystone service list
            foreach my $service (@{$services->{services}}) {
                next if $options{custom}->is_excluded_service(type => 'service', service => $service);

                foreach my $endpoint (@{$service->{endpoints}}) {
                    next if $options{custom}->is_excluded_endpoint($endpoint);

                    my $result = $options{custom}->ping_service(type => $service->{type},
                                                                service_url => $endpoint->{url},
                                                                inscure => $options{custom}->{insecure_service},
                                                                endpoint_suffix => $self->{endpoint_suffix},
                                                                expected_data => $self->{expected_data}
                                                            );

                    # Retry one time if unauthorized
                    next RETRY if $result->{http_status} == 401 && $retry == 1;

                    $self->{services}->{$count++} = { type => $service->{type},
                                                      name => $service->{name},
                                                      interface => $endpoint->{interface},
                                                      region => $endpoint->{region},
                                                      %$result }
                }
            }
        }
        last
    }

    $self->{global} = { count => $count };
}

1;

__END__

=head1 MODE

OpenStack Services mode

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^count$'

=item B<--service-url>

Define the endpoint URL to check (can be multiple).
When using this option the service type and name are set to C<service> and C<N/A> if
not already defined with C<--include-type> and C<--include-name> options.
When this option is not set the endpoints to test are taken from the cached C<Keystone>
service list previously generated with 'discovery' and 'list-services' commands and
filtered by C<--include-*> and C<--exclude-*> options below.

=item B<--include-service-type>

Filter by service type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-service-type>

Exclude by service type (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-service-name>

Filter by service name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-service-name>

Exclude by service name (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-service-id>

Filter by service id (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-service-id>

Exclude by service id (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-endpoint-region>

Filter by service region (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-endpoint-region>

Exclude by service region (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-endpoint-region-id>

Filter by service region ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--exclude-endpoint-region-id>

Exclude by service region ID (can be a regexp and can be used multiple times or for comma separated values).

=item B<--include-endpoint-interface>

Filter by service interface ID (can be a regexp and can be used multiple times or for comma separated values).
OpenStack interfaces are 'public', 'internal', 'admin'.

=item B<--exclude-endpoint-interface>

Exclude by service interface (can be a regexp and can be used multiple times or for comma separated values).
OpenStack interfaces are 'public', 'internal', 'admin'.

=item B<--expected-data>

Data that endpoint should return when it is normally working (default value: C<auto>).
When C<auto> is set the connector automatically defines the value depending on the C<type> of endpoint.
When a non empty value is set it represents a value that must be present in the returned data.
If this option is not set the check only verifies that the data is a valid JSON.
The result of this check 1/0 is saved in %{valid_content} variable.

=item B<--endpoint-suffix>

Append a specific suffix to he endpoint URL URL for the heath check (default value: C<auto>).
When C<auto> is set the connector automatically defines the suffix depending on the C<type> of endpoint.
When C<none> is set no suffix is appended.

=back

=cut
