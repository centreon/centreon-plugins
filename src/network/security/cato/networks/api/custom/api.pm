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

package network::security::cato::networks::api::custom::api;

use strict;
use warnings;

use JSON::XS;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/value_of json_encode graphql_escape/;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'api-key:s'         => { name => 'api_key',         default => '' },
            'account-id:s'      => { name => 'account_id',      default => '' },
            'proto:s'           => { name => 'proto',           default => 'https' },
            'port:s'            => { name => 'port',            default => 443 },
            'hostname:s'        => { name => 'hostname',        default => 'api.catonetworks.com' },
            'endpoint:s'        => { name => 'endpoint',        default => '/api/v1/graphql2' },
            'max-retry-count:s' => { name => 'max_retry_count', default => 5 },
            'timeout:s'         => { name => 'timeout',         default => 10 },
            'retry-delay:s'     => { name => 'retry_delay',     default => 5 }
        });

    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'GRAPHQL API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    foreach my $opt (qw/account_id api_key port hostname endpoint proto max_retry_count retry_delay timeout/) {
        $self->{$opt} = $self->{option_results}->{$opt};

        $self->{output}->option_exit(short_msg => "Need to specify --".($opt=~s/_/-/gr)." option.")
            if $self->{$opt} eq '';
    }
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'x-api-key', value => $self->{api_key});
    $self->{http}->add_header(key => 'Content-type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $tried = 0;
    my $decoded;

    my $full_query = json_encode({ query => "{ $options{query} }" } );

    $self->{output}->option_exit(short_msg => "Cannot encode json request !")
        unless $full_query;

    # This retry system is used to handle the Cato API rate limiting, as described at https://support.catonetworks.com/hc/en-us/articles/5119033786653-Understanding-Cato-API-Rate-Limiting
    # Retry up to max_retry_count (5) times with a delay of retry_delay (5) seconds between attemps on rate limiting errors
    # For others error, retry with a 1 second delay between attemps
    while (1) {
        $tried++;
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => $self->{endpoint},
            query_form_post => $full_query,
            silently_fail => 1 # silently_fail is set to correctly handle errors returned by the API
        );

        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };

        if ($@) {
            if ($tried < $self->{max_retry_count}) {
                sleep(1);
                next
            }
            $self->{output}->option_exit(short_msg => "Cannot decode json response: $@");
        }

        if ($decoded->{errors} || not $decoded->{data}) {
            if ($tried < $self->{max_retry_count}) {
                my $delay = value_of($decoded, "->{errors}->[0]->{message}") =~ /rate limit for operation/i ? $self->{retry_delay} : 1;

                sleep($delay);
                next
            }
            $self->{output}->option_exit(short_msg => "Graph endpoint API return error '" . ($decoded->{errors}->[0]->{message} // 'Invalid content')  . "' (add --debug option for detailed message)");
        }
        last
    }

    return $decoded;
}


sub sites_accountSnapshot {
    my ($self, %options) = @_;

    my $siteIDs = @{$options{filter_site_id}} ?
                        " ( siteIDs: [". ( join ", ", map { '"' . graphql_escape($_) . '"' } @{$options{filter_site_id}} ) ."] )" :
                        '';

    my $query = qq~accountSnapshot(
                     accountID: "$self->{account_id}"
                   ) {
                     sites$siteIDs {
                       id
                       info {
                         name
                         description
                       }
                       connectivityStatus
                       operationalStatus
                       lastConnected
                       connectedSince
                       popName
                     }
                   }~;

    my $response = $self->request_api(query => $query);

    my %sites;

    if (ref $response->{data}->{accountSnapshot}->{sites} eq 'ARRAY') {
        foreach my $site (@{$response->{data}->{accountSnapshot}->{sites}}) {
            $sites{ $site->{id} } = {
                id => $site->{id},
                name => $site->{info}->{name},
                description => $site->{info}->{description},
                connectivity_status => $site->{connectivityStatus},
                operational_status => $site->{operationalStatus},
                last_connected => $site->{lastConnected},
                connected_since => $site->{connectedSince},
                pop_name => $site->{popName}
            };
        }
    }

    return \%sites;
}

our @performance_metrics = qw/bytesUpstreamMax bytesDownstreamMax lostUpstreamPcnt lostDownstreamPcnt packetsDiscardedDownstream packetsDiscardedUpstream jitterUpstream jitterDownstream lastMilePacketLoss lastMileLatency/;

sub sites_accountMetrics {
    my ($self, %options) = @_;

    return {} unless ref $options{performance_metrics} eq 'HASH' && scalar keys %{$options{performance_metrics}};

    my $siteIDs = @{$options{filter_site_id}} ?
                        "( siteIDs: [". ( join ", ", map { '"' . graphql_escape($_) . '"' } @{$options{filter_site_id}} ) ."] )" :
                        '';

    my $metrics = join ', ', keys %{$options{performance_metrics}};

    my $timeframe = $options{timeframe} || 'last.PT5M';
    my $buckets = $options{buckets} || 10;

    my $query = qq~accountMetrics(
                     accountID: "$self->{account_id}",
                     timeFrame: "$timeframe",
                     groupInterfaces: true
                   ) {
                     from
                     to
                     sites$siteIDs {
                       id
                       interfaces {
                         name
                         timeseries (labels:[ $metrics ] buckets: $buckets) {
                           label
                           units
                           data
                         }
                       }
                     }
                   }~;

    my $response = $self->request_api(query => $query);

    my %sites_metrics;

    if (ref $response->{data}->{accountMetrics}->{sites} eq 'ARRAY') {
        foreach my $site (@{$response->{data}->{accountMetrics}->{sites}}) {
            $sites_metrics{ $site->{id} } = {};

            foreach my $timeseries (@{$site->{interfaces}->[0]->{timeseries}}) {
                $sites_metrics{ $site->{id} }->{$timeseries->{label}} = [ map { { timestamp => $_->[0], value => $_->[1] } } @{$timeseries->{data}} ];
            }
        }
    }

    return \%sites_metrics;
}

sub list_sites {
    my ($self, %options) = @_;

    my @response;
    my ($from, $count) = (0, 0);

    # Use native search filter if filter_site_name is provided
    my $search = $options{filter_site_name} ne '' ?
                    # Ensure any double quotes in filter_site_name are properly escaped
                    ', search: "'.graphql_escape($options{filter_site_name}). '"' :
                    '';

    my $entityIDs = @{$options{filter_site_id}} ?
                        ", entityIDs: [". ( join ", ", map { '"' . graphql_escape($_) . '"' } @{$options{filter_site_id}} ) ."]" :
                        '';

    while (1) {
        # Building an entityLoop query using pagination. The "limit" parameter is not specified as the default value 50 is used
        my $query = qq~entityLookup(
                         accountID: $self->{account_id},
                         type: site,
                         from: $from
                         $search
                         $entityIDs
                       ) {
                         total
                         items {
                           entity {
                             id
                             name
                           }
                           description
                         }
                       }
                       ~;

        my $part = $self->request_api(query => $query);

        last if ref $part->{data}->{entityLookup}->{items} ne 'ARRAY' || @{$part->{data}->{entityLookup}->{items}} == 0;

        $from += @{$part->{data}->{entityLookup}->{items}};

        push @response, map { $_->{entity} } @{$part->{data}->{entityLookup}->{items}};

        last if $from == $part->{data}->{entityLookup}->{total};
    }

    my @entityIDs = map { $_->{id} } @response;

    if (@entityIDs) {
        if ($options{connectivity_details}) {
            # Queries connectivity details if requested
            my $sites_snap = $self->sites_accountSnapshot (filter_site_id => \@entityIDs );

            foreach my $site (@response) {
                next unless exists $sites_snap->{ $site->{id} };
                my $ref = $sites_snap->{ $site->{id} };

                $site->{$_} = $ref->{$_} foreach qw/connectivity_status operational_status last_connected connected_since pop_name description/;
            }
        } else {
            # Otherwise set empty values
            foreach my $site (@response) {
                $site->{$_} = '' foreach qw/connectivity_status operational_status last_connected connected_since pop_name description/;
            }
        }
    }

    return \@response;
}

sub check_connectivity {
    my ($self, %options) = @_;

    my $site_id = $options{site_id};

    my $enable_performance_metrics = $options{performance_metrics} && ref($options{performance_metrics}) eq 'HASH' && keys %{$options{performance_metrics}} ? 1 : 0;

    my $site_snap_list = $self->sites_accountSnapshot ( filter_site_id => [ $site_id ] );

    my $site_snap = value_of($site_snap_list, "->{$site_id}", {});

    my $sites_metrics;
    if ($enable_performance_metrics) {
        $sites_metrics = $self->sites_accountMetrics ( filter_site_id => [ $site_id ],
                                                       timeframe => graphql_escape($options{timeframe}),
                                                       buckets => $options{buckets},
                                                       performance_metrics => $options{performance_metrics} );
        return { %{$site_snap},
                 performance => ($sites_metrics->{$site_id} // '')
               };

    }

    return { %{$site_snap} };
}

sub send_custom_query {
    my ($self, %options) = @_;

    my $arguments = $options{arguments} && @{$options{arguments}} ?
                            ', '.join ', ',@{$options{arguments}} :
                            '';

    my $query = $options{operation}.qq~( accountID: "$self->{account_id}"$arguments
                   ) { $options{query}
                   }~;

    my $response = $self->request_api(query => $query);

    return $response->{data}->{$options{operation}};
}

1;

__END__

=head1 NAME

Cato Networks Monitoring via GraphQL API

=head1 GRAPHQL API OPTIONS

=over 8

=item B<--api-key>

Cato Networks API authentication key.

=item B<--account-id>

Account ID.

=item B<--hostname>

Cato Networks API hostname (default: C<api.catonetworks.com>).

=item B<--proto>

Protocol used (default: 'https').

=item B<--endpoint>

Cato GraphQL API relative endpoint URI (default : C</api/v1/graphql2>).

=item B<--max-retry-count>

Maximum number of retry attempts (default: 5).

=item B<--retry-delay>

Delay between retries in seconds (default: 5).

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
