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

package network::freebox::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON;
use Digest::SHA qw(hmac_sha1_hex);

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
            'hostname:s@'            => { name => 'hostname' },
            'freebox-app-id:s@'      => { name => 'freebox_app_id' },
            'freebox-app-token:s@'   => { name => 'freebox_app_token' },
            'freebox-api-version:s@' => { name => 'freebox_api_version', },
            'timeout:s@'             => { name => 'timeout' },
            'resolution:s@'          => { name => 'resolution' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    $self->{session_token} = undef;

    return $self;

}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname}            = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : 'mafreebox.free.fr';
    $self->{freebox_app_id}      = (defined($self->{option_results}->{freebox_app_id})) ? shift(@{$self->{option_results}->{freebox_app_id}}) : undef;
    $self->{freebox_app_token}   = (defined($self->{option_results}->{freebox_app_token})) ? shift(@{$self->{option_results}->{freebox_app_token}}) : undef;
    $self->{freebox_api_version} = (defined($self->{option_results}->{freebox_api_version})) ? shift(@{$self->{option_results}->{freebox_api_version}}) : 'v4';
    $self->{timeout}    = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{resolution} = (defined($self->{option_results}->{resolution})) ? shift(@{$self->{option_results}->{resolution}}) : 300;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{freebox_app_id})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify freebox-app-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{freebox_app_token})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify freebox-app-token option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{freebox_app_id}) ||
        scalar(@{$self->{option_results}->{freebox_app_id}}) == 0) {
        return 0;
    }
    return 1;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = 80;
    $self->{option_results}->{proto} = 'http';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    if (defined($self->{session_token})) {
        $self->{http}->add_header(key => 'X-Fbx-App-Auth', value => $self->{session_token});
    }
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_response {
    my ($self, %options) = @_;
    
    if ($self->{http}->get_code() != 200) {
        $self->{output}->add_option_msg(short_msg => "Connection issue: " . $options{content});
        $self->{output}->option_exit();
    }
    
    my $decoded;
    eval {
        $decoded = decode_json($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    
    if (!$decoded->{success}) {
        $self->{output}->add_option_msg(short_msg => "Unsuccessful $options{type} response");
        $self->{output}->option_exit();
    }
    
    return $decoded;
}

sub get_session {
    my ($self, %options) = @_;
    
    $self->settings();
    my $content = $self->{http}->request(url_path => '/api/' . $self->{freebox_api_version} . '/login/',
                                         critical_status => '', warning_status => '', unknown_status => '');
    my $decoded = $self->manage_response(content => $content, type => 'login');
    my $challenge = $decoded->{result}->{challenge};
    my $password = hmac_sha1_hex($challenge, $self->{freebox_app_token});
    
    my $json_request = { app_id => $self->{freebox_app_id}, password => $password };
    my $encoded;
    eval {
        $encoded = encode_json($json_request);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }
    
    $content = $self->{http}->request(url_path => '/api/' . $self->{freebox_api_version} . '/login/session/', method => 'POST',
                                      query_form_post => $encoded, critical_status => '', warning_status => '', unknown_status => '');
    $decoded = $self->manage_response(content => $content, type => 'login/session');
    
    $self->{session_token} = $decoded->{result}->{session_token};
}

sub get_data {
    my ($self, %options) = @_;
    
    if (!defined($self->{session_token})) {
        $self->get_session();
    }
    
    $self->settings();
    my $content = $self->{http}->request(url_path => '/api/' . $self->{freebox_api_version} . '/' . $options{path},
                                         critical_status => '', warning_status => '', unknown_status => '');
    my $decoded = $self->manage_response(content => $content, type => $options{path});
    return $decoded->{result};
}

sub get_performance {
    my ($self, %options) = @_;

    if (!defined($self->{session_token})) {
        $self->get_session();
    }
    
    my $json_request = { db => $options{db}, date_start => time() - $self->{resolution}, precision => 100 };
    my $encoded;
    eval {
        $encoded = encode_json($json_request);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot encode json request');
        $self->{output}->option_exit();
    }
    
    $self->settings();
    my $content = $self->{http}->request(
        url_path => '/api/' . $self->{freebox_api_version} . '/' . $options{path},
        method => 'POST', query_form_post => $encoded, 
        critical_status => '', warning_status => '', unknown_status => ''
    );
    my $decoded = $self->manage_response(content => $content);

    my ($datas, $total) = ({}, 0);
    foreach my $data (@{$decoded->{result}->{data}}) {
        foreach my $label (keys %$data) {
            next if ($label eq 'time');
            $datas->{$label} = 0 if (!defined($datas->{$label}));
            $datas->{$label} += $data->{$label};
        }
        $total++;
    }
    
    $datas->{$_} = $datas->{$_} / $total / 100 foreach (keys %$datas);

    return $datas;
}

sub DESTROY {
    my $self = shift;

    if (defined($self->{session_token})) {
        $self->{http}->request(url_path => '/api/' . $self->{freebox_api_version} . '/login/logout/', method => 'POST');
    }
}

1;

__END__

=head1 NAME

FREEBOX REST API

=head1 SYNOPSIS

Freebox Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Freebox hostname (Default: 'mafreebox.free.fr').

=item B<--freebox-app-id>

Freebox App ID.

=item B<--freebox-app-token>

Freebox App Token.

=item B<--freebox-api-version>

Freebox API version (Default: 'v4').

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=item B<--resolution>

Selected data performance resolution in seconds (Default: '300').

=back

=head1 DESCRIPTION

B<custom>.

=cut
