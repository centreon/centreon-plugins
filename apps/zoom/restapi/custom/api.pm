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

package apps::zoom::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use DateTime;
use Digest::MD5 qw(md5_hex);
use JSON::XS;
use JSON::WebToken;

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
            'hostname:s'   => { name => 'hostname' },
            'url-path:s'   => { name => 'url_path' },
            'port:s'       => { name => 'port' },
            'proto:s'      => { name => 'proto' },
            'api-key:s'    => { name => 'api_key' },
            'api-secret:s' => { name => 'api_secret' },
            'timeout:s'    => { name => 'timeout' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'api.zoom.us';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/v2';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_key} = (defined($self->{option_results}->{api_key})) ? $self->{option_results}->{api_key} : '';
    $self->{api_secret} = (defined($self->{option_results}->{api_secret})) ? $self->{option_results}->{api_secret} : '';

    if (!defined($self->{api_key}) || $self->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-key option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_secret}) || $self->{api_secret} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-secret option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{url_path} = $self->{url_path};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{jwt_token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{jwt_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_jwt_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'zoom_api_' . md5_hex($self->{api_key}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $jwt_token = $options{statefile}->get(name => 'jwt_token');

    if ($has_cache_file == 0 || !defined($jwt_token) || (($expires_on - time()) < 10)) {
        my $exp = time() + 3600;

        $jwt_token = JSON::WebToken->encode({
            alg => "HS256",
            typ => "JWT",
            iss => $self->{api_key},
            exp => $exp,
        }, $self->{api_secret}, 'HS256');

        my $datas = { last_timestamp => time(), jwt_token => $jwt_token, expires_on => $exp };
        $options{statefile}->write(data => $datas);
    }
    
    return $jwt_token;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{jwt_token})) {
        $self->{jwt_token} = $self->get_jwt_token(statefile => $self->{cache});
    }

    $self->settings;
    
    $self->{output}->output_add(long_msg => "Query URL: '" . $self->{proto} . "://" . $self->{hostname} .
        $self->{url_path} . $options{url_path} . "'", debug => 1);

    my $content = $self->{http}->request(url_path => $self->{url_path} . $options{url_path});

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
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

Zoom Rest API

=head1 SYNOPSIS

Zoom Rest API custom mode

=head1 REST API OPTIONS

Zoom Rest API

=over 8

=item B<--hostname>

Zoom API hostname (Default: 'api.zoom.us')

=item B<--port>

API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--url-path>

API URL path (Default: '/v2')

=item B<--api-key>

JWT app API key.

=item B<--api-secret>

JWT app API secret.

=item B<--timeout>

Set HTTP timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
