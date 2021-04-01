#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::slack::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

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
            'hostname:s'  => { name => 'hostname' },
            'port:s'      => { name => 'port' },
            'proto:s'     => { name => 'proto' },
            'timeout:s'   => { name => 'timeout' },
            'api-path:s'  => { name => 'api_path' },
            'api-token:s' => { name => 'api_token' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'slack.com';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : undef;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/api';
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : undef;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_token})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify api-token option.");
        $self->{output}->option_exit();
    }
    
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    if (defined($self->{token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $content = $self->{http}->request(method => $options{method}, url_path => $self->{api_path} . $options{url_path},
        query_form_post => $options{query_form_post}, critical_status => '', warning_status => '', unknown_status => '');
    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    if ($decoded->{ok} != 1) {
        $self->{output}->add_option_msg(short_msg => "Error: " . $decoded->{error});
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_api_token {
    my ($self, %options) = @_;

    if (defined($self->{api_token}) && $self->{api_token} ne '') {
        return $self->{api_token};
    }
    # OAuth2 not handled 
    
    return;
}

sub get_object {
    my ($self, %options) = @_;

    if (!defined($self->{token})) {
        $self->{token} = $self->get_api_token();
    }

    my $result = $self->request_api(%options);

    return $result;
}

1;

__END__

=head1 NAME

Slack REST API

=head1 SYNOPSIS

Slack Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Slack API hostname (Default: 'slack.com').

=item B<--api-path>

Slack API url path (Default: '/api').

=item B<--api-token>

Slack API token of a user or app with following
permissions : 'users:read', 'channels:read'.

=item B<--port>

Slack API port

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
