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

package cloud::openshift::api::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc qw(json_decode value_of);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    unless ($options{output}) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }

    $options{options}->add_options(arguments => {
            'hostname:s'  => { name => 'hostname',  default => '' },
            'port:s'      => { name => 'port',      default => 6443 },
            'proto:s'     => { name => 'proto',     default => 'https' },
            'token:s'     => { name => 'token',     default => '' },
            'timeout:s'   => { name => 'timeout',   default => 10 },
            'limit:s'     => { name => 'limit',     default => 100 }
    }) unless $options{noptions};

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/hostname port proto token timeout limit/;

    $self->{timeout} = $self->{timeout} =~ /(\d+)/ ? $1 : 10;
    $self->{limit} = $self->{limit} =~ /(\d+)/ ? $1 : 100;

    $self->{output}->option_exit(short_msg => "Need to specify --hostname option.")
        if $self->{hostname} eq '';
    $self->{output}->option_exit(short_msg => "Need to specify --token option.")
        if $self->{token} eq '';

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{$_} = $self->{$_}
        foreach qw/hostname timeout port proto/;
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{token})
        if $self->{token};
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    $self->{output}->output_add(
        long_msg => "URL: '" . $self->{proto} . '://' . $self->{hostname} .
        ':' . $self->{port} . $options{url_path} . "'",
        debug => 1
    );

    my $content = $self->{http}->request(%options);

    if ($self->{http}->get_code() != 200) {
        my $decoded = json_decode($content,
            output => $self->{output},
            no_exit => 1
        );

        my $msg = value_of($decoded, "->{message}", $self->{http}->get_message() || 'Internal Error');
        $self->{output}->option_exit(short_msg => "OpenShift API returned an error '$msg'")
            if $msg && $self->{http}->get_code() == 401;
        $self->{output}->option_exit(short_msg => "OpenShift API returned an error code '" . ($decoded->{code} // $self->{http}->get_code()). "': $msg (add --debug option for detailed message)");
    }

    my $decoded = json_decode(
        $content,
        output => $self->{output},
    );

    return $decoded;
}

sub request_api_paginate {
    my ($self, %options) = @_;

    my @items;
    my @get_param = ( 'limit=' . $self->{limit} );
    push @get_param, @{$options{get_param}} if $options{get_param};

    while (1) {
        my $response = $self->request_api(
            method => $options{method},
            url_path => $options{url_path},
            get_param => \@get_param
        );
        last unless ref $response->{items} eq 'ARRAY';
        push @items, @{$response->{items}};

        last unless $response->{metadata}->{continue};
        @get_param = ( 'limit=' . $self->{limit}, 'continue=' . $response->{metadata}->{continue} );
        push @get_param, @{$options{get_param}} if $options{get_param};
    }

    return \@items;
}

sub openshift_list_routes {
    my ($self, %options) = @_;

    my $url_path = $options{namespace} ? '/apis/route.openshift.io/v1/namespaces/' . $options{namespace} . '/routes' : '/apis/route.openshift.io/v1/routes';

    my $response = $self->request_api_paginate(
        method => 'GET',
        url_path => $url_path
    );

    return $response;
}

sub openshift_list_clusteroperators {
    my ($self, %options) = @_;

    my $url_path = '/apis/config.openshift.io/v1/clusteroperators';

    my $response = $self->request_api_paginate(
        method => 'GET',
        url_path => $url_path
    );

    return $response;
}

sub openshift_list_projects {
    my ($self, %options) = @_;

    my $url_path = '/apis/project.openshift.io/v1/projects';

    my $response = $self->request_api_paginate(
        method => 'GET',
        url_path => $url_path
    );

    return $response;
}

sub openshift_list_clusterversions {
    my ($self, %options) = @_;

    my $url_path = '/apis/config.openshift.io/v1/clusterversions';

    my $response = $self->request_api_paginate(
        method => 'GET',
        url_path => $url_path
    );

    return $response;
}

1;

__END__

=head1 NAME

OpenShift Rest API

=head1 SYNOPSIS

OpenShift Rest API custom mode

=head1 REST API OPTIONS

OpenShift Rest API

=over 8

=item B<--hostname>

OpenShift API hostname.

=item B<--port>

API port (default: 6443).

=item B<--proto>

Specify https if needed (default: 'https').

=item B<--timeout>

Set HTTP timeout (default: 10).

=item B<--limit>

Number of responses to return for each list calls (default: 100).

=back

=head1 DESCRIPTION

B<custom>.

=cut
