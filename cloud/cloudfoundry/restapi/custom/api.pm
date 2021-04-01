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

package cloud::cloudfoundry::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use URI::Encode;

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
            'username:s'     => { name => 'username' },
            'password:s'     => { name => 'password' },
            'timeout:s'      => { name => 'timeout' },
            'api-path:s'     => { name => 'api_path' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : 'cf';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/v2';
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : undef;
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : undef;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_username})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify API username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_password})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify API password option.");
        $self->{output}->option_exit();
    }
    
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    if (defined($self->{access_token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

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
    if ($self->{http}->get_code() != 200) {
        $self->{output}->add_option_msg(short_msg => "Error code: " . $decoded->{error_code} . ". Description: " . $decoded->{description});
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_info {
    my ($self, %options) = @_;

    $self->settings();
    
    return $self->request_api(method => 'GET', url_path => '/info');
}
   

sub get_access_token {
    my ($self, %options) = @_;

    my $info = $self->get_info();

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $encoded_username = $uri->encode($self->{api_username});
    my $encoded_password = $uri->encode($self->{api_password});

    my $content = $self->{http}->request(method => 'POST', query_form_post => 'username=' . $encoded_username . '&password=' . $encoded_password . '&grant_type=password',
                                        full_url => $info->{authorization_endpoint} . '/oauth/token', hostname => '',
                                        basic => 1, credentials => 1, username => $self->{username}, password => $self->{password});
    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    
    return $decoded->{access_token};
}

sub get_object_v2 {
    my ($self, %options) = @_;

    $self->settings();

    my $url_path = $options{url_path};

    my @result;
    while(my $content = $self->request_api(%options)) {
        if (defined($content->{resources})) {
            push @result, @{$content->{resources}};
            last if (!defined($content->{next_url}) ||
                $content->{next_url} !~ /^$self->{api_path}$url_path.*&page=(.*).*/ ||
                $content->{next_url} !~ /^$self->{api_path}$url_path.*?page=(.*).*/);
            my $page = $1;
            $options{url_path} = $url_path . '?page=' . $page;
        } else {
            return $content;
            last;
        }
    }

    return \@result;
}

sub get_object_v3 {
    my ($self, %options) = @_;
    
    $self->settings();

    my $url_path = $options{url_path};

    my @result;
    while(my $content = $self->request_api(%options)) {
        if (defined($content->{resources})) {
            push @result, @{$content->{resources}};
            last if (!defined($content->{pagination}->{next}->{href}) ||
                $content->{pagination}->{next}->{href} !~ /^$self->{proto}\:\/\/$self->{hostname}$self->{api_path}$url_path.*&page=(.*).*/ ||
                $content->{pagination}->{next}->{href} !~ /^$self->{proto}\:\/\/$self->{hostname}$self->{api_path}$url_path.*?page=(.*).*/);
            my $page = $1;
            $options{url_path} = $url_path . '?page=' . $page;
        } else {
            push @result, $content;
            last;
        }
    }

    return \@result;
}

sub get_object {
    my ($self, %options) = @_;

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token();
    }

    my $info = $self->get_info();

    if ($info->{api_version} =~ /^2\..*/) {    
        return $self->get_object_v2(%options);
    } else {
        return $self->get_object_v3(%options); # Not tested
    }

    return undef;
}

1;

__END__

=head1 NAME

Cloud Foundry REST API

=head1 SYNOPSIS

Cloud Foundry Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Cloud Foundry API hostname.

=item B<--api-path>

Cloud Foundry API url path (Default: '/v2')

=item B<--api-username>

Cloud Foundry API username.

=item B<--api-password>

Cloud Foundry API password.

=item B<--port>

Cloud Foundry API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--username>

Authorization endpoint username (Default: 'cf')

=item B<--password>

Authorization endpoint password (Default: '')

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
