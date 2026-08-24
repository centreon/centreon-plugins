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

package apps::virtualization::vates::custom::api;
use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc qw/json_encode json_decode is_empty/;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.");
    }

    $options{options}->add_options(
        arguments => {
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port', default => '443' },
            'proto:s'    => { name => 'proto', default => 'https' },
            'username:s' => { name => 'username' },
            'password:s' => { name => 'password' },
            'api-key:s'  => { name => 'api_key' },
            'timeout:s'  => { name => 'timeout', default => 10 },
            'api-url:s'  => {name => 'api_url', default => '/rest/v0/' }
        });

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output}          = $options{output};
    $self->{http}            = centreon::plugins::http->new(%options, 'default_backend' => 'curl');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub check_options {
    my $self = shift;
    if (!$self->{option_results}->{password} && !$self->{option_results}->{api_key}){
                $self->{output}->option_exit(short_msg => "Need to specify --password or --api-key option.");
    }
    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --hostname option.");
    }
    if ($self->{option_results}->{username} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --username option.");
    }
    $self->{http}->set_options(%{$self->{option_results}});
    # set auth header
    $self->{auth_header} = MIME::Base64::encode_base64($self->{option_results}->{username} . ':' . $self->{option_results}->{password});
    chomp($self->{auth_header});

    return 0;
}
sub request_api {
    my ($self, %options) = @_;
    my @header = ('Authorization: Basic ' . $self->{auth_header});

    if ($options{header}) {
        print("inserting\n");
        push @header, @{$options{header}};
    }
     my ($content) = $self->{http}->request(
        method          => 'GET',
        url_path        => $self->{option_results}->{api_url} . $options{endpoint},
        get_param       => $options{get_param},
        header          => \@header,
     );
    return json_decode($content, booleans_as_strings => 1);

}

sub request_api_get {
    my ($self, %options) = @_;

    my ($content) = $self->request_api(%options, method => "GET");

    return $content;
}

1;