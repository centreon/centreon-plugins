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

package apps::centreon::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

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
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'api-path:s'     => { name => 'api_path' },
            'timeout:s'      => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 80;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ?
        $self->{option_results}->{api_username} : undef;
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ?
        $self->{option_results}->{api_password} : undef;
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ?
        $self->{option_results}->{api_path} : '/centreon/api/index.php';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
 
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_username}) || $self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_password}) || $self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;
    
    return $self->{hostname}  . '_' . $self->{http}->get_port();
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{auth_token})) {
        $self->{http}->add_header(key => 'Centreon-Auth-Token', value => $self->{auth_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_auth_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'centreon_api_' . md5_hex($self->{hostname}) .
        '_' . md5_hex($self->{api_username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $auth_token = $options{statefile}->get(name => 'auth_token');

    if ($has_cache_file == 0 || !defined($auth_token) || (($expires_on - time()) < 10)) {
        my $post_param = [ 'username=' . $self->{api_username}, 'password=' . $self->{api_password} ];

        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/centreon/api/index.php?action=authenticate',
            post_param => $post_param
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }
        if (!defined($decoded->{authToken})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $auth_token = $decoded->{authToken};
        my $datas = { last_timestamp => time(), auth_token => $decoded->{authToken}, expires_on => time() + 3600 };
        $options{statefile}->write(data => $datas);
    }
    
    return $auth_token;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{auth_token})) {
        $self->{auth_token} = $self->get_auth_token(statefile => $self->{cache});
    }

    $self->settings();
    
    my $encoded_form_post;
    eval {
        $encoded_form_post = JSON::XS->new->utf8->encode($options{query_form_post});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    my $content = $self->{http}->request(
        method => $options{method},
        url_path => $options{url_path},
        query_form_post => $encoded_form_post,
        header => $options{header},
        critical_status => '',
        warning_status => '',
        unknown_status => ''
    );

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    return ($decoded, JSON::XS->new->utf8->pretty->encode($decoded));
}

sub submit_result {
    my ($self, %options) = @_;
    
    my ($response, $raw) = $self->request_api(
        method => 'POST',
        url_path => $self->{api_path} . '?action=submit&object=centreon_submit_results',
        query_form_post => $options{post_data},
        header => ['Content-Type: application/json']
    );
    
    return ($response, $raw);
}

1;

__END__

=head1 NAME

Centreon REST API

=head1 SYNOPSIS

Centreon Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Centreon hostname.

=item B<--port>

Port used (Default: 80)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--api-username>

Centreon username.

=item B<--api-password>

Centreon password.

=item B<--api-path>

API base url path (Default: '/centreon/api/index.php').

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=back

=head1 DESCRIPTION

B<custom>.

=cut
