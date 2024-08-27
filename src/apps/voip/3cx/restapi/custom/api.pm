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

package apps::voip::3cx::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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
        $options{options}->add_options(arguments =>  {
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port'},
            'proto:s'                => { name => 'proto' },
            '3cx-version:s'          => { name => 'version_3cx' },
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
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

    $self->{hostname}               = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port}                   = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto}                  = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{version_3cx}            = (defined($self->{option_results}->{version_3cx})) ? $self->{option_results}->{version_3cx} : '';
    $self->{timeout}                = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{ssl_opt}                = (defined($self->{option_results}->{ssl_opt})) ? $self->{option_results}->{ssl_opt} : undef;
    $self->{api_username}           = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password}           = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status}    = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status}    = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status}   = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }
    $self->{option_results}->{api_version} = $self->get_api_version(version_3cx => $self->{option_results}->{version_3cx});
    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{ssl_opt} = $self->{ssl_opt};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json;charset=UTF-8');
    if (defined($self->{cookie})) {
        $self->{http}->add_header(key => 'Cookie', value => $self->{cookie});

        if (defined($self->{auth_header})) {
            my $auth_header_key = ( $self->{option_results}->{api_version} == 1 )
                                ? 'X-XSRF-TOKEN'
                                : 'Authorization';
            $self->{http}->add_header(key => $auth_header_key, value => $self->{auth_header});
        }
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub authenticate {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => '3cx_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $cookie = $options{statefile}->get(name => 'cookie');
    my $auth_header = $options{statefile}->get(name => 'auth_header');
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    
    if ($has_cache_file == 0 || !defined($cookie) || !defined($auth_header) || (($expires_on - time()) < 10)) {
        my $post_data = '{"Username":"' . $self->{api_username} . '",' .
            '"Password":"' . $self->{api_password} . '"}';
        
        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST', query_form_post => $post_data,
            url_path => '/api/login',
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $header = $self->{http}->get_header(name => 'Set-Cookie');
        # 3CX v16 cookie name is .AspNetCore.Cookies
        # 3CX v18 cookie name is .AspNetCore.CookiesA
        if (defined ($header) && $header =~ /(?:^| )(.AspNetCore.Cookies[A]?=[^;]+);.*/) {
            $cookie = $1;
        } else {
            $self->{output}->add_option_msg(short_msg => "Error retrieving cookie");
            $self->{output}->option_exit();
        }

        my $data;
        if ($self->{option_results}->{api_version} == 1)
        {
            # for 3CX versions prior to 18.0.5
            # 3CX 16.0.5.611 does not use XSRF-TOKEN anymore
            if (defined ($header) && $header =~ /(?:^| )XSRF-TOKEN=([^;]+);.*/) {
                $auth_header = $1;
            }
            $data = { last_timestamp => time(), cookie => $cookie, xsrf => $auth_header, expires_on => time() + (3600 * 24) };
        } else {
            # for 3CX versions higher or equal to 18.0.5
            $self->{http}->add_header(key => 'Cookie', value => $cookie);
            $content = $self->{http}->request(
                method => 'GET',
                url_path => '/api/Token',
                unknown_status => $self->{unknown_http_status},
                warning_status => $self->{warning_http_status},
                critical_status => $self->{critical_http_status}
            );
            my $decoded;
            eval {
                $decoded = JSON::XS->new->decode($content);
            };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
                $self->{output}->option_exit();
            }
            if (!defined($decoded)) {
                $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
                $self->{output}->option_exit();
            }
            $auth_header = $decoded->{token_type} . " " . $decoded->{access_token};
            $expires_on = time() + ($decoded->{expires_in} * 60);

            $data = { last_timestamp => time(), cookie => $cookie, bearer => $auth_header, expires_on => $expires_on };
        }

        $options{statefile}->write(data => $data);
    }

    $self->{cookie} = $cookie;
    $self->{auth_header} = $auth_header;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{cookie})) {
        $self->authenticate(statefile => $self->{cache});
    }

    $self->settings();

    my $content = $self->{http}->request(
        %options,
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    # Some content may be strangely returned, for example :
    # 3CX <  16.0.2.910 : "[{\"Category\":\"provider\",\"Count\":1}]"
    # 3CX >= 16.0.2.910 : {"tcxUpdate":"[{\"Category\":\"provider\",\"Count\":5},{\"Category\":\"sp150\",\"Count\":1}]","perPage":"[]"}
    if (defined($options{eval_content}) && $options{eval_content} == 1) {
        if (my $evcontent = eval "$content") {
            $content = $evcontent;
        }
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub internal_activecalls {
    my ($self, %options) = @_;
    
    my $status = $self->request_api(method => 'GET', url_path =>'/api/activeCalls');
    return $status;
}

sub api_activecalls {
    my ($self, %options) = @_;

    my $status = $self->internal_activecalls();
    return $status->{list};
}

sub internal_extension_list {
    my ($self, %options) = @_;
    
    my $status = $self->request_api(method => 'GET', url_path =>'/api/ExtensionList');
    return $status;
}

sub api_extension_list {
    my ($self, %options) = @_;

    my $status = $self->internal_extension_list();
    return $status->{list};
}

sub internal_single_status {
    my ($self, %options) = @_;

    my $status = $self->request_api(method => 'GET', url_path =>'/api/SystemStatus/GetSingleStatus');
    return $status;
}

sub api_single_status {
    my ($self, %options) = @_;

    my $status = $self->internal_single_status();
    return $status->{Health};
}

sub internal_system_status {
    my ($self, %options) = @_;
    
    my $status = $self->request_api(method => 'GET', url_path =>'/api/SystemStatus');
    return $status;
}

sub api_system_status {
    my ($self, %options) = @_;

    my $status = $self->internal_system_status();
    return $status;
}

sub internal_update_checker_v1 {
    my ($self, %options) = @_;
    
    my $status = $self->request_api(method => 'GET', url_path =>'/api/UpdateChecker/GetFromParams', eval_content => 1);
    if (ref($status) eq 'HASH') {
        $status = $status->{tcxUpdate};
        if (ref($status) ne 'ARRAY') {
            # See above note about strange content
            $status = JSON::XS->new->decode($status);
        }
    }
    return $status;
}

sub internal_update_checker_v2 {
    my ($self, %options) = @_;

    my $status = $self->request_api(method => 'GET', url_path =>'/xapi/v1/GetUpdatesStats()');
    if (ref($status) eq 'HASH') {
        $status = $status->{TcxUpdate};
        if (ref($status) ne 'ARRAY') {
            # See above note about strange content
            $status = JSON::XS->new->decode($status);
        }
    }
    return $status;
}


sub api_update_checker {
    my ($self, %options) = @_;

    if ($self->{option_results}->{api_version} == 1){
        return $self->internal_update_checker_v1();
    }
    return $self->internal_update_checker_v2();
}

sub get_api_version {
    my ($self, %options) = @_;

    # Given the provided (or not) 3cx version, determine once and for all the API version
    # This API version is an internal reference in centreon-plugins
    # Version 1 corresponds to versions prior to v18 update 5 (<= 18.0.4.x)
    # Version 2 corresponds to versions greater or equal to v18 update 5 (> 18.0.5.0)

    # assuming the lastest API version if not provided
    return 2 if ( !defined($options{version_3cx}) );

    my @version_decomposition = $options{version_3cx} =~ /^([0-9]+)\.?([0-9]*)\.?([0-9]*)\.?([0-9]*)$/;

    if (scalar(@version_decomposition) == 0){
        $self->{output}->add_option_msg(
            debug => 1,
            long_msg => "Version '" . $options{version_3cx} . "' not formatted properly. Switching to latest supported version.");
        return 2;
    }

    if ($version_decomposition[0] < 18
        or $version_decomposition[0] == 18
            and defined($version_decomposition[1]) and $version_decomposition[1] == 0
            and defined($version_decomposition[2]) and $version_decomposition[2] < 5) {

        $self->{output}->add_option_msg(
            debug => 1,
            long_msg => "Version '" . $options{version_3cx} . "' identified as prior to 18 update 5. Using old API.");
        return 1;
    } else {
        $self->{output}->add_option_msg(
            debug => 1,
            long_msg => "Version '" . $options{version_3cx} . "' identified as higher or equal to 18 update 5. Using new API.");
        return 2;
    }
}

1;

__END__

=head1 NAME

3CX Rest API module

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Define the name or the address of the 3CX server.

=item B<--port>

Define the port to connect to (default: '443').

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--3cx-version>

Define the version of 3CX to monitor for the plugin to adapt to the API version. If this option is omitted, the plugin will assume the API is in the latest supported version.
Example: 18.0.9.20 for version 18 update 9.


=item B<--api-username>

Define the username for authentication.

=item B<--api-password>

Define the password associated with the username.

=item B<--timeout>

Define the timeout in seconds (default: 30).

=item B<--unknown-http-status>

Define the conditions to match on the HTTP Status for the returned status to be UNKNOWN.
Default: '%{http_code} < 200 or %{http_code} >= 300'

=item B<--warning-http-status>

Define the conditions to match on the HTTP Status for the returned status to be WARNING.
Example: '%{http_code} == 500'

=item B<--critical-http-status>

Define the conditions to match on the HTTP Status for the returned status to be CRITICAL.
Example: '%{http_code} == 500'

=back

=cut
