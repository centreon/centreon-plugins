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

package apps::ipfabric::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'    => { name  => 'hostname' },
            'url-path:s'    => { name  => 'url_path' },
            'port:s'        => { name  => 'port' },
            'proto:s'       => { name  => 'proto' },
            'api-key:s'     => { name  => 'api_key' },
            'timeout:s'     => { name  => 'timeout' },
            'snapshot-id:s' => { name  => 'snapshot_id' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/api/v6.2/tables';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_key} = (defined($self->{option_results}->{api_key})) ? $self->{option_results}->{api_key} : '';
    $self->{snapshot_id} = (defined($self->{option_results}->{snapshot_id})) ? $self->{option_results}->{snapshot_id} : '$last';

    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }

    if ($self->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-key option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{curl_opt})) {
        $self->{option_results}->{curl_opt} = ['CURLOPT_POSTREDIR => CURL_REDIR_POST_ALL'];
        $self->{curl_opt} = 'CURLOPT_POSTREDIR => CURL_REDIR_POST_ALL';
    }
    
    return 0;
}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'X-API-Token', value => $self->{api_key});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $encoded_form_post;
    if (defined($options{query_form_post})) {
        $options{query_form_post}->{snapshot} = $self->{snapshot_id};
        eval {
            $encoded_form_post = JSON::XS->new->utf8->encode($options{query_form_post});
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
            $self->{output}->option_exit();
        }
    }

    my ($content) = $self->{http}->request(
        method => 'POST',
        url_path => $self->{url_path} . $options{endpoint},
        query_form_post => $encoded_form_post
    );

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

IP Fabric API module.

=head1 REST API OPTIONS

IP Fabric API module.

=over 8

=item B<--hostname>

Set hostname, it is mandatory.

=item B<--snapshot-id>

Specify snapshot ID from which you want to base monitoring.

If no snapshot ID is specified, the last one is set by default.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify http if needed (default: 'https')

=item B<--api-key>

Set API key to request IP Fabric API.

=item B<--timeout>

Set timeout in seconds (default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
