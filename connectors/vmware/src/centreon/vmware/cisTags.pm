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

package centreon::vmware::cisTags;

use strict;
use warnings;
use centreon::vmware::http::http;
use JSON::XS;

# https://developer.vmware.com/apis/vsphere-automation/v7.0U2/cis/

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{is_error} = 1;
    $self->{error} = 'configuration missing';
    $self->{is_logged} = 0;

    return $self;
}

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{is_error} = 1;
        $self->{error} = "cannot decode json response: $@";
        return undef;
    }

    return $decoded;
}

sub error {
    my ($self, %options) = @_;

    return $self->{error};
}

sub configuration {
    my ($self, %options) = @_;

    foreach (('url', 'username', 'password')) {
        if (!defined($options{$_}) ||
            $options{$_} eq '') {
            $self->{error} = $_ . ' configuration missing';
            return 1;
        }

        $self->{$_} = $options{$_};
    }

    if ($self->{url} =~ /^((?:http|https):\/\/.*?)\//) {
        $self->{url} = $1;
    }

    $self->{http_backend} = defined($options{backend}) ? $options{backend} : 'curl';

    $self->{curl_opts} = ['CURLOPT_SSL_VERIFYPEER => 0', 'CURLOPT_POSTREDIR => CURL_REDIR_POST_ALL'];
    my $curl_opts = [];
    if (defined($options{curlopts})) {
        foreach (keys %{$options{curlopts}}) {
            push @{$curl_opts}, $_ . ' => ' . $options{curlopts}->{$_};
        }
    }
    if (scalar(@$curl_opts) > 0) {
        $self->{curl_opts} = $curl_opts;
    }

    $self->{http} = centreon::vmware::http::http->new(logger => $options{logger});
    $self->{is_error} = 0;
    return 0;
}

sub authenticate {
    my ($self, %options) = @_;

    my ($code, $content) = $self->{http}->request(
        http_backend => $self->{http_backend},
        method => 'POST',
        query_form_post => '',
        hostname => '',
        full_url => $self->{url} . '/rest/com/vmware/cis/session',
        header => [
            'Accept-Type: application/json; charset=utf-8',
            'Content-Type: application/json; charset=utf-8',
        ],
        curl_opt => $self->{curl_opts},
        credentials => 1,
        basic => 1,
        username => $self->{username},
        password => $self->{password},
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );
    if ($code) {
        $self->{is_error} = 1;
        $self->{error} = 'http request error';
        return undef;
    }
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{is_error} = 1;
        $self->{error} =  "Login error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']";
        return undef;
    }

    my $decoded = $self->json_decode(content => $content);
    return if (!defined($decoded));

    my $token = defined($decoded->{value}) ? $decoded->{value} : undef;
    if (!defined($token)) {
        $self->{is_error} = 1;
        $self->{error} = 'authenticate issue - cannot get token';
        return undef;
    }

    $self->{token} = $token;
    $self->{is_logged} = 1;
}

sub request {
    my ($self, %options) = @_;

    if (!defined($self->{url})) {
        $self->{is_error} = 1;
        $self->{error} = 'configuration missing';
        return 1;
    }

    $self->{is_error} = 0;
    if ($self->{is_logged} == 0) {
        $self->authenticate();
    }

    return 1 if ($self->{is_logged} == 0);

    my ($code, $content) = $self->{http}->request(
        http_backend => $self->{http_backend},
        method => $options{method},
        hostname => '',
        full_url => $self->{url} . $options{endpoint},
        query_form_post => $options{query_form_post},
        get_param => $options{get_param},
        header => [
            'Accept-Type: application/json; charset=utf-8',
            'Content-Type: application/json; charset=utf-8',
            'vmware-api-session-id: ' . $self->{token}
        ],
        curl_opt => $self->{curl_opts},
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    my $decoded = $self->json_decode(content => $content);

    # code 403 means forbidden (token not good maybe)
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{token} = undef;
        $self->{is_logged} = 0;
        $self->{is_error} = 1;
        $self->{error} = $content;
        $self->{error} = $decoded->{value}->[0]->{default_message} if (defined($decoded) && defined($decoded->{value}->[0]->{default_message}));
        return 1;
    }

    return 1 if (!defined($decoded));

    return (0, $decoded);
}

sub tagsByResource {
    my ($self, %options) = @_;

    my ($code, $tag_ids) = $self->request(
        method => 'GET',
        endpoint => '/rest/com/vmware/cis/tagging/tag'
    );
    return $code if ($code);

    my $tags = {};
    my $result = { esx => {} , vm => {} };
    if (defined($tag_ids->{value})) {
        my $json_req = { tag_ids => [] };
        foreach my $tag_id (@{$tag_ids->{value}}) {
            my ($code, $tag_detail) = $self->request(
                method => 'GET',
                endpoint => '/rest/com/vmware/cis/tagging/tag/id:' . $tag_id
            );
            return $code if ($code);

            push @{$json_req->{tag_ids}}, $tag_id; 
            $tags->{ $tag_id } = { name => $tag_detail->{value}->{name}, description => $tag_detail->{value}->{description} };
        }

        my $data;
        eval {
            $data = encode_json($json_req);
        };
        if ($@) {
            $self->{is_error} = 1;
            $self->{error} = "cannot encode json request: $@";
            return undef;
        }

        my ($code, $tags_assoc) = $self->request(
            method => 'POST',
            endpoint => '/rest/com/vmware/cis/tagging/tag-association',
            get_param => ['~action=list-attached-objects-on-tags'],
            query_form_post => $data
        );
        return $code if ($code);

        if (defined($tags_assoc->{value})) {
            foreach my $entry (@{$tags_assoc->{value}}) {
                foreach my $entity (@{$entry->{object_ids}}) {
                    if ($entity->{type} eq 'VirtualMachine') {
                        $result->{vm}->{ $entity->{id} } = [] if (!defined($result->{vm}->{ $entity->{id} }));
                        push @{$result->{vm}->{ $entity->{id} }}, $tags->{ $entry->{tag_id} };
                    } elsif ($entity->{type} eq 'HostSystem') {
                        $result->{esx}->{ $entity->{id} } = [] if (!defined($result->{esx}->{ $entity->{id} }));
                        push @{$result->{esx}->{ $entity->{id} }}, $tags->{ $entry->{tag_id} };
                    }
                }
            }
        }
    }

    return (0, $result);
}

sub DESTROY {
    my ($self) = @_;

    if ($self->{is_logged} == 1) {
        $self->request(
            method => 'DELETE',
            endpoint => '/rest/com/vmware/cis/session'
        );
    }
}

1;
