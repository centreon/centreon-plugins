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

package apps::backup::rubrik::graphql::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_encode json_decode is_empty value_of is_excluded flatten_arrays json_to_sha256 date_xm_ago_utc/;
use apps::backup::rubrik::graphql::common qw/period_to_date is_uuid/;
use Digest::SHA qw(sha256_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    die "Class Custom: Need to specify 'output' argument.\n"
        unless $options{output};

    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    $options{options}->add_options(arguments => {
        'service-account:s'      => { name => 'service_account',      default => '' },
        'secret:s'               => { name => 'secret',               default => '' },
        'hostname:s'             => { name => 'hostname',             default => '' },
        'port:s'                 => { name => 'port',                 default => '443' },
        'proto:s'                => { name => 'proto',                default => 'https' },
        'timeout:s'              => { name => 'timeout',              default => 120 }, # Rubrik requests can take a long time
        'unknown-http-status:s'  => { name => 'unknown_http_status',  default => '' },
        'warning-http-status:s'  => { name => 'warning_http_status' },
        'critical-http-status:s' => { name => 'critical_http_status' },
        'token:s'                => { name => 'token' },
        'limit:s'                => { name => 'limit' },
        'disable-cache'          => { name => 'disable_cache' },
        'cache-ttl:s'            => { name => 'cache_ttl',            default => 240 }, # 4 hours
        'cache-use'              => { name => 'cache_use' }, # always use cache

        # Common cluster filtering options
        'cluster:s@'             => { name => 'cluster' },
        'include-cluster:s'      => { name => 'include_cluster',      default => '' },
        'exclude-cluster:s'      => { name => 'exclude_cluster',      default => '' },
    }) unless $options{noptions};

    $options{options}->add_help(package => __PACKAGE__, sections => 'GRAPHQL API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache_connect} = centreon::plugins::statefile->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{$_} = $self->{option_results}->{$_} foreach qw/token service_account secret unknown_http_status warning_http_status critical_http_status cache_use limit/;

    $self->{cache_ttl} = $self->{option_results}->{cache_ttl} * 60;

    if ($self->{limit}) {
        $self->{output}->option_exit(short_msg => '--limit must be a positive number.')
            unless $self->{limit} =~ /^\d+$/;
        $self->{limit} = int $self->{limit};
    }

    $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.')
        if $self->{option_results}->{hostname} eq '';
    $self->{option_results}->{hostname} .= ".my.rubrik.com" unless $self->{option_results}->{hostname}=~/\./;

    unless ($self->{token}) {
        $self->{output}->option_exit(short_msg => 'Need to specify --service-account option.')
            if $self->{service_account} eq '';

        $self->{output}->option_exit(short_msg => 'Need to specify --secret option.')
            if $self->{option_results}->{secret} eq '';
    } else {
        $self->{output}->option_exit(short_msg => 'Cannot use --token and --service-account/--secret together.')
            if $self->{service_account} ne '' || $self->{secret} ne '';
    }

    $self->{option_results}->{cluster} = flatten_arrays($self->{option_results}->{cluster});

    $self->{cache_connect}->check_options(option_results => $self->{option_results});
    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    if ($options{content_type}) {
        $self->{http}->add_header(key => 'Content-Type', value => $options{content_type});
    } else {
        $self->{http}->remove_header(key => 'Content-Type');
    }
    return if $self->{settings_done};

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port} . '-' . $self->{service_account};
}

sub get_rsc_token {
    my ($self, %options) = @_;

    $self->{cache_connect}->read(statefile => 'rubrik_graphql_' . sha256_hex($self->get_connection_info()));
    my $token = $self->{cache_connect}->get(name => 'access_token', default => '');
    my $expires_at = $self->{cache_connect}->get(name => 'expires_at', default => 0);
    my $sha_secret_cache = $self->{cache_connect}->get(name => 'sha_secret', default => '');
    my $sha_secret = sha256_hex($self->{option_results}->{service_account} . $self->{option_results}->{secret});

    if ($token eq '' ||
        $expires_at < time() + 60 ||
        $sha_secret_cache ne $sha_secret) {
        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/api/client_token',
            post_params => { 'client_id' => $self->{service_account}, 'client_secret' => $self->{secret}, 'grant_type' => 'client_credentials' },
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $decoded = json_decode($content, output => $self->{output});

        $token = $decoded->{access_token};
        my $expires_in = $decoded->{expires_in} // 43200; # 12h by default
        my $datas = {
            updated      => time(),
            access_token => $token,
            expires_at   => time() + $expires_in,
            sha_secret   => $sha_secret
        };
        $self->{cache_connect}->write(data => $datas);
    }

    return $token;
}

sub clean_token {
    my ($self, %options) = @_;

    undef $self->{token};
    my $datas = { updated => time() };
    $self->{cache_connect}->write(data => $datas);
}

sub credentials {
    my ($self, %options) = @_;

    $self->{token} //= $self->get_rsc_token();

    return 'Authorization: Bearer ' . ($self->{token} // '')
}

sub request_graphql {
    my ($self, %options) = @_;

    my $credentials = $self->credentials();

    my $query = { query => $options{query},
                  variables => $options{variables} || {}
                };
    my $encoded = json_encode ($query, output => $self->{output});
    $self->settings(content_type => 'application/json');

    my $content = $self->{http}->request(
        method => 'POST',
        url_path => '/api/graphql',
        query_form_post => $encoded,
        header => [ $credentials ],
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);
    return if $self->{http}->get_code() == 401; # Need authentication

    my $decoded = json_decode($content, allow_nonref => 1, output => $self->{output});

    # Handling different error cases
    if ($self->{http}->get_code() == 400) {
        my $error_msg = value_of($decoded, "->{message}", 'Unknown error');

        if (length($error_msg) > 100) {
            if ($self->{output}->is_verbose()) {
              $self->{output}->add_option_msg(long_msg => $error_msg);
              $error_msg = 'Invalid request';
            } else {
              $error_msg = 'Invalid request, use --verbose option to get more details';
            }
        }
        $self->{output}->option_exit(short_msg => $error_msg);
    }
    if (ref $decoded eq 'HASH' && ref $decoded->{errors} eq 'ARRAY') {
        my $error_msg = join '; ', map { $_->{message} } grep { $_->{message} } @{$decoded->{errors}};
        $self->{output}->option_exit(short_msg => "Rubrik failed to parse the request: $error_msg") if $error_msg;
    }

    return $decoded->{data};
}

sub request_api {
    my ($self, %options) = @_;

    my $data = $self->request_graphql(%options);

    # Maybe token is invalid so we retry
    if ($self->{service_account} ne ''&& ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300)) {
        $self->clean_token();
        $data = $self->request_graphql(%options);
    }

    $self->{output}->option_exit(short_msg => "Authentication failed !")
        if $self->{http}->get_code() == 401;

    return $data;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_rubrik_' . $options{statefile} . '_' . sha256_hex($self->get_connection_info()));
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_rubrik_' . $options{statefile} . '_' . sha256_hex($self->get_connection_info()));
    my $response = $self->{cache}->get(name => 'response');
    $self->{output}->option_exit(short_msg => 'Cache file missing')
        unless $response;

    return $response;
}

sub get_jobs_monitoring {
    my ($self, %options) = @_;

    my $first = $options{limit} || $self->{limit};

    my $variables = { };
    $variables->{first} = $first if $first;

    # Build ActivitySeriesFilter filters
    $variables->{filters} = $options{filters}
        if ref $options{filters} eq 'HASH';

    my $query = q{
        ($first: Int, $after: String, $filters: ActivitySeriesFilter) {
            activitySeriesConnection(
                first: $first,
                after: $after,
                filters: $filters
            ) {
                edges {
                    node {
                        objectName
                        fid
                        objectType
                        startTime
                        lastUpdated
                        lastActivityType
                        lastActivityStatus
                        failureReason
                        location
                        clusterName
                        cluster {
                            id
                        }
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
    };

    return $self->request_api_paginate( description => 'getActivitySeries', object => 'activitySeriesConnection', query => $query, variables => $variables, filter => 'filters' );
}

sub get_protection_tasks {
    my ($self, %options) = @_;

    my $first = $options{limit} || $self->{limit};

    my $variables = { };
    $variables->{first} = $first if $first;

    # Build TaskDetailFilterInput filters
    $variables->{filter} = {  taskCategory => [ 'Protection' ],
#                              taskStatus => [ 'Success', 'Failed', 'Canceled' ],
                              %{$options{filters} // { } }
                           };

    my $query = q{
        ($first: Int, $after: String, $filter: TaskDetailFilterInput, $sortBy: TaskDetailSortByEnum, $sortOrder: SortOrder) {
            taskDetailConnection(
                first: $first,
                after: $after,
                filter: $filter,
                sortBy: $sortBy,
                sortOrder: $sortOrder
            ) {
                edges {
                    node {
                        clusterName
                        clusterUuid
                        startTime
                        endTime
                        objectName
                        objectType
                        failureReason
                        taskCategory
                        taskType
                        status
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
    };

    return $self->request_api_paginate( description => 'getProtectionTasksStatus', object => 'taskDetailConnection', query => $query, variables => $variables );
}

sub request_api_paginate {
    my ($self, %options) = @_;

    my $query = "query $options{description} $options{query}";
    my $variables = $options{variables};
    my $object = $options{object};
    my $filter = $options{filter} // 'filter';

    my $cached_data = $self->read_cache(query => $options{description}, identifiers => $variables);

    return $cached_data if defined $cached_data;

    foreach my $ts (qw/time_gt time_lt registrationTime_gt registrationTime_lt startTimeGt startTimeLt lastUpdatedTimeGt lastUpdatedTimeLt/) {
        next unless $variables->{$filter}->{$ts};

        if ($variables->{$filter}->{$ts}=~/^\d+$/) {
            # Converting interval to date
            $variables->{$filter}->{$ts} = date_xm_ago_utc( $variables->{$filter}->{$ts} );
        } elsif (length($variables->{$filter}->{$ts}) == 10) {
            # If no time (HH:mm:ss) is specified a default is applied:
            # 00:00:00 for 'gt' comparisons and 23:59:59 for 'lt' comparisons
            my $end = $ts =~ /gt$/i ? '00:00:00' : '23:59:59';
            $variables->{$filter}->{$ts}.='T'.$end.'Z';
        } elsif (length($variables->{$filter}->{$ts}) == 19) {
            $variables->{$filter}->{$ts}=~s/\s/T/;
            $variables->{$filter}->{$ts}.='Z';
        }
    }

    my $items = [];
    my $after;

    while (1) {
        $variables->{after} = $after if $after;

        my $result = $self->request_api(
            query => $query,
            variables => $variables
        );

        if (ref $result->{$object}->{edges} eq 'ARRAY') {

            foreach my $edge (@{$result->{$object}->{edges}}) {
                push @$items, $edge->{node};
            }
        }

        my $hasNextPage = value_of($result, "->{$object}->{pageInfo}->{hasNextPage}", "");
        $after = value_of($result, "->{$object}->{pageInfo}->{endCursor}", '');
        last unless $hasNextPage && $after;

    }

    $self->write_cache(data => $items);

    return $items;
}

sub common_filters {
    my ($self, %options) = @_;

    my %filters;

    if ($self->{option_results}->{cluster}) {
        my (@uuid, @name);

        foreach my $ident (@{$self->{option_results}->{cluster}}) {
            next if is_empty($ident);
            if (is_uuid($ident)) {  # Filter is a UUID
                push @uuid, $ident;
            } else {
                push @name, $ident;
            }
       }
       $filters{id} = \@uuid if @uuid;
       $filters{name} = \@name if @name;
    }

    return \%filters;
}


sub is_common_excluded {
    my ($self, %options) = @_;

    my $no_id = is_empty($options{id});
    my $no_name = is_empty($options{name});

    return 0 if $no_id && $no_name;

    # Check if each defined element is excluded (using both include and exclude filters)
    my $id_excluded = !$no_id && is_excluded($options{id}, $self->{option_results}->{include_cluster}, $self->{option_results}->{exclude_cluster});
    my $name_excluded = !$no_name && is_excluded($options{name}, $self->{option_results}->{include_cluster}, $self->{option_results}->{exclude_cluster});

    # Exclude if all defined elements are excluded
    if (($no_id || $id_excluded) && ($no_name || $name_excluded)) {
        $self->{output}->output_add(long_msg => "skipping '".($options{id} // '')."' '".($options{name} // '')."': excluded by a filter.", debug => 1);
        return 1
    }

    # Otherwise include (at least one defined element is included)
    return 0;
}

sub get_all_clusters_uuid {
    my ($self, %options) = @_;

    my $query = q{
        {
           clusterConnection {
              edges {
                  node {
                      id
                      name
                  }
              }
              pageInfo {
                  hasNextPage
                  endCursor
              }
           }
        }
    };

    return $self->request_api_paginate( description => 'clusterUuid', object => 'clusterConnection', query => $query );
}

sub clusters_uuid_from_name {
    my ($self, @names) = @_;

    my @uuids;

    unless ($self->{_cluster_name_uuid}) {
        my $data = $self->get_all_clusters_uuid();
        return \@uuids unless ref $data eq 'ARRAY';

        $self->{_cluster_name_uuid} = {};
        foreach my $item (@{$data}) {
            $self->{_cluster_name_uuid}->{$item->{name}} = $item->{id};
        }
    }

    foreach my $name (@names) {
        push @uuids, $self->{_cluster_name_uuid}->{$name} if $self->{_cluster_name_uuid}->{$name};
    }

    return \@uuids;
}

sub get_cluster_stats {
    my ($self, %options) = @_;

    my $first = $options{limit} || $self->{limit};

    my $variables = { };
    $variables->{first} = $first if $first;

    # Build ClusterFilterInput filters
    $variables->{filter} = $options{filters}
        if ref $options{filters} eq 'HASH';

    # Query detailed stats for selected cluster
    my $query = q{
        ($first: Int, $after: String, $filter: ClusterFilterInput, $sortBy: ClusterSortByEnum, $sortOrder: SortOrder) {
            clusterConnection(
                first: $first, after: $after, filter: $filter, sortBy: $sortBy, sortOrder: $sortOrder
            ) {
                edges {
                    node {
                        id
                        name
                        status
                        systemStatus
                        isHealthy
                        clusterNodeStats {
                            clusterPhysicalDataIngest
                            readThroughputBytesPerSecond
                            writeThroughputBytesPerSecond
                            networkBytesReceived
                            networkBytesTransmitted
                            iopsReadsPerSecond
                            iopsWritesPerSecond
                        }
                        ipmiInfo {
                            isAvailable
                            usesHttps
                            usesIkvm
                        }
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
    };

    return $self->request_api_paginate( description => 'clusterStats', object => 'clusterConnection', query => $query, variables => $variables );
}

sub get_cluster_storage {
    my ($self, %options) = @_;

    my $first = $options{limit} || $self->{limit};

    my $variables = { };
    $variables->{first} = $first if $first;

    # Build ClusterFilterInput filters
    $variables->{filter} = $options{filters}
        if ref $options{filters} eq 'HASH';

    # Query detailed stats for selected cluster
    my $query = q{
        ($first: Int, $after: String, $filter: ClusterFilterInput, $sortBy: ClusterSortByEnum, $sortOrder: SortOrder) {
            clusterConnection(
                first: $first, after: $after, filter: $filter, sortBy: $sortBy, sortOrder: $sortOrder
            ) {
                edges {
                    node {
                        id
                        name
                        estimatedRunway
                        metric {
                            availableCapacity
                            averageDailyGrowth
                            totalCapacity
                            usedCapacity
                        }
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
    };

    return $self->request_api_paginate( description => 'clusterStorage', object => 'clusterConnection', query => $query, variables => $variables );
}

sub get_cluster_nodes {
    my ($self, %options) = @_;

    my $first = $options{limit} || $self->{limit};

    my $variables = { };
    $variables->{first} = $first if $first;

    # Build ClusterFilterInput filters
    $variables->{filter} = $options{filters}
        if ref $options{filters} eq 'HASH';

    # Query detailed stats for selected cluster
    my $query = q{
        ($first: Int, $after: String, $filter: ClusterFilterInput, $sortBy: ClusterSortByEnum, $sortOrder: SortOrder) {
            clusterConnection(
                first: $first, after: $after, filter: $filter, sortBy: $sortBy, sortOrder: $sortOrder
            ) {
                edges {
                    node {
                        id
                        name
                        clusterNodeConnection {
                            nodes {
                                id
                                hostname
                                ipAddress
                                status
                            }
                        }
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
    };

    return $self->request_api_paginate( description => 'clusterNodes', object => 'clusterConnection', query => $query, variables => $variables );
}

sub get_cluster_disks {
    my ($self, %options) = @_;

    my $first = $options{limit} || $self->{limit};

    my $variables = { };
    $variables->{first} = $first if $first;

    # Build ClusterFilterInput filters
    $variables->{filter} = $options{filters}
        if ref $options{filters} eq 'HASH';

    # Query detailed stats for selected cluster
    my $query = q{
        ($first: Int, $after: String, $filter: ClusterFilterInput, $sortBy: ClusterSortByEnum, $sortOrder: SortOrder) {
            clusterConnection(
                first: $first, after: $after, filter: $filter, sortBy: $sortBy, sortOrder: $sortOrder
            ) {
                edges {
                    node {
                        id
                        name
                        clusterDiskConnection {
                            nodes {
                                status
                                path
                                diskId
                                serial
                                isEncrypted
                                raidStatus
                                raidType
                                nodeId
                            }
                        }
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
    };

    return $self->request_api_paginate( description => 'clusterDisks', object => 'clusterConnection', query => $query, variables => $variables );
}

sub read_cache {
    my ($self, %options) = @_;

    return undef if $self->{option_results}->{disable_cache};

    my $query = $options{query};
    my $data = $options{identifiers};

    my $cache_file = "rubrik_graphql_" . $query . '_' . json_to_sha256(prefix => $self->get_connection_info(), data => $data);
    $self->{cache}->{datas} = {};
    $self->{cache}->read(statefile => $cache_file);

    my $created_at = $self->{cache}->get(name => 'created_at', default => 0);
    my $cached_data = $self->{cache}->get(name => 'items');

    return $cached_data if ($self->{cache_use} || $created_at + $self->{cache_ttl} > time()) && ref $cached_data eq 'ARRAY'; # && @{$cached_data};

    $self->{output}->option_exit(short_msg => "No cached data available. You must provide cache files or remove the --cache-use option.")
        if $self->{cache_use};

    return undef
}

sub write_cache {
    my ($self, %options) = @_;

    return if $self->{option_results}->{disable_cache};

    $self->{cache}->write(data => { created_at => time(), items => $options{data} } );
}

sub get_snappable_compliance {
    my ($self, %options) = @_;

    my $first = $options{limit} || $self->{limit};
    my $after;

    my $variables = { };
    $variables->{first} = $first if $first;

    $variables->{filter} = $options{filters}
        if ref $options{filters} eq 'HASH';

    my $query = q{
        ($first: Int, $after: String, $filter: SnappableFilterInput) {
            snappableConnection(
                first: $first,
                after: $after,
                filter: $filter
            ) {
                edges {
                    node {
                        id
                        name
                        location
                        objectType
                        missedSnapshots
                        complianceStatus
                        protectionStatus
                        cluster {
                            id
                            name
                        }
                        slaDomain {
                            name
                        }
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }

            }
        }
    };

    return $self->request_api_paginate( description => 'getSnappableCompliance', object => 'snappableConnection', query => $query, variables => $variables );
}

1;

__END__

=head1 NAME

Rubrik GraphQL API

=head1 GRAPHQL API OPTIONS

Rubrik GraphQL API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Protocol used (default: 'https').

=item B<--service-account>

Service account ID (with --secret option).

=item B<--secret>

Service account secret (with --service-account option).

=item B<--token>

Use token authentication. If option is specified, token is used directly instead of service account credentials.

=item B<--timeout>

Set timeout in seconds (default: 120).

=item B<--unknown-http-status>

Unknown HTTP status code.

=item B<--warning-http-status>

Warning HTTP status code.

=item B<--critical-http-status>

Critical HTTP status code.

=item B<--limit>

Define the number of entries to retrieve for the pagination.

=item B<--disable-cache>

Disable the cache feature.

=item B<--cache-ttl>

Cache time to live in minutes (default: 240 = 4 hours).

=item B<--cache-use>

Always use cached data, ignoring the --cache-ttl expiration time.

=item B<--cluster>

Filter cluster. Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).
Depending on its format this parameter is treated as either a name or a UUID.

=item B<--include-cluster>

Include cluster (can be a regexp).
Depending on its format this parameter is treated as either a name or a UUID.

=item B<--exclude-cluster>

Exclude cluster (can be a regexp).
Depending on its format this parameter is treated as either a name or a UUID.

=back

=head1 DESCRIPTION

B<custom>.

=cut
