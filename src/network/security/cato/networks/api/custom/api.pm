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
use centreon::plugins::misc qw/value_of json_encode/;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

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

        next if $self->{$opt} ne '';

        $self->{output}->add_option_msg(short_msg => "Need to specify --".($opt=~s/_/-/gr)." option.");
        $self->{output}->option_exit();
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

    my $full_query = json_encode({ query => $options{query} });

    unless ($full_query) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request !");
        $self->{output}->option_exit();
    }

    # This retry system is used to handle the Cato API rate limiting, as described at https://support.catonetworks.com/hc/en-us/articles/5119033786653-Understanding-Cato-API-Rate-Limiting
    # Retry up to max_retry_count (5) times with a delay of retry_delay (5) seconds between attemps on rate limiting errors
    # For others error, retry with a 1 second delay between attemps
    while (1) {
        $tried++;
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => $self->{endpoint},
            query_form_post => $full_query
        );

        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };

        if ($@) {
            if ($tried < $self->{max_retry_count}) {
                sleep(1);
                next
            }
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
            $self->{output}->option_exit();
        }

        if ($decoded->{errors}) {
            if ($tried < $self->{max_retry_count}) {
                my $delay = value_of($decoded, "->{errors}->[0]->{message}") =~ /rate limit for operation/i ? $self->{retry_delay} : 1;

                sleep($delay);
                next
            }
            $self->{output}->add_option_msg(short_msg => "Graph endpoint API return error '" . $decoded->{error}->[0]->{message}  . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }
        last
    }

    return $decoded;
}


sub list_sites {
    my ($self, %options) = @_;

    my @response;
    my ($from, $count) = (0, 0);

    # Use native search filter if filter_site_name is provided
    my $search = $options{filter_site_name} ne '' ?
                    # Ensure any double quotes in filter_site_name are properly escaped
                    ', search: "'.$options{filter_site_name} =~ s/"/\\"/gr.'"' :
                    '';

    while (1) {
        # Building an entityLoop query using pagination. The "limit" parameter is not specified as the default value 50 is used
        my $query = qq/entityLookup(accountID: "$self->{account_id}", type: site, from: $from, sort: { field: name, order: asc}$search ) { total items { entity { id name } }/;

        my $part = $self->request_api(query => $query);

        last if ref $part->{data}->{entityLookup}->{items} ne 'ARRAY' || @{$part->{data}->{entityLookup}->{items}} == 0;

        $from += @{$part->{data}->{entityLookup}->{items}};

        push @response, map { $_->{entity} } @{$part->{data}->{entityLookup}->{items}};

        last if $from == $part->{data}->{entityLookup}->{total};
    }

    return \@response;
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
