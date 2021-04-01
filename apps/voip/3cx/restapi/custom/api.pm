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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{ssl_opt} = (defined($self->{option_results}->{ssl_opt})) ? $self->{option_results}->{ssl_opt} : undef;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

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
        $self->{http}->add_header(key => 'Cookie', value => '.AspNetCore.Cookies=' . $self->{cookie});
        if (defined($self->{xsrf})) {
            $self->{http}->add_header(key => 'X-XSRF-TOKEN', value => $self->{xsrf});
        }
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub authenticate {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => '3cx_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $cookie = $options{statefile}->get(name => 'cookie');
    my $xsrf = $options{statefile}->get(name => 'xsrf');
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    
    if ($has_cache_file == 0 || !defined($cookie) || !defined($xsrf) || (($expires_on - time()) < 10)) {
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
        if (defined ($header) && $header =~ /(?:^| ).AspNetCore.Cookies=([^;]+);.*/) {
            $cookie = $1;
        } else {
            $self->{output}->add_option_msg(short_msg => "Error retrieving cookie");
            $self->{output}->option_exit();
        }
        # 3CX 16.0.5.611 does not use XSRF-TOKEN anymore
        if (defined ($header) && $header =~ /(?:^| )XSRF-TOKEN=([^;]+);.*/) {
            $xsrf = $1;
        }

        my $datas = { last_timestamp => time(), cookie => $cookie, xsrf => $xsrf, expires_on => time() + (3600 * 24) };
        $options{statefile}->write(data => $datas);
    }

    $self->{cookie} = $cookie;
    $self->{xsrf} = $xsrf;
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

sub internal_update_checker {
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

sub api_update_checker {
    my ($self, %options) = @_;

    my $status = $self->internal_update_checker();
    return $status;
}

1;

__END__

=head1 NAME

3CX Rest API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Set hostname or IP of 3CX server.

=item B<--port>

Set 3CX Port (Default: '443').

=item B<--proto>

Specify http if needed (Default: 'https').

=item B<--api-username>

Set 3CX Username.

=item B<--api-password>

Set 3CX Password.

=item B<--timeout>

Threshold for HTTP timeout (Default: '30').

=item B<--unknown-http-status>
Threshold unknown for http response code.
(Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-http-status>
Threshold warning for http response code.

=item B<--critical-http-status>
Threshold critical for http response code.

=back

=cut
