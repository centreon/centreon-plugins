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

package apps::monitoring::dynatrace::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
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
            'hostname:s'       => { name => 'hostname' },
            'environment-id:s' => { name => 'environment_id' },
            'port:s'           => { name => 'port'},
            'proto:s'          => { name => 'proto' },
            'api-password:s'   => { name => 'api_password' },
            'timeout:s'        => { name => 'timeout', default => 30 }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'live.dynatrace.com';
    $self->{environment_id} = (defined($self->{option_results}->{environment_id})) ? $self->{option_results}->{environment_id} : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{ssl_opt} = (defined($self->{option_results}->{ssl_opt})) ? $self->{option_results}->{ssl_opt} : undef;
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : undef;

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{environment_id}) || $self->{environment_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --environment-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_password}) || $self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    if ($self->{hostname} eq 'live.dynatrace.com') {
        $self->{option_results}->{hostname} = $self->{environment_id} . '.' . $self->{hostname};
    } else {
        $self->{option_results}->{hostname} = $self->{hostname};
    }
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{ssl_opt} = $self->{ssl_opt};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json;charset=UTF-8');
    $self->{http}->add_header(key => 'Authorization', value => 'Api-Token ' . $self->{option_results}->{api_password});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(%options, 
        warning_status => '', unknown_status => '%{http_code} < 200 or %{http_code} >= 300', critical_status => ''
    );

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded)) {
        $self->{output}->output_add(long_msg => $decoded, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub internal_problem {
    my ($self, %options) = @_;

    my $status = $self->request_api(method => 'GET', url_path => (($self->{hostname} eq 'live.dynatrace.com') ? '' : '/e') . '/api/v1/problem/feed?relativeTime=' . $self->{option_results}->{relative_time});
    return $status;
}

sub api_problem {
    my ($self, %options) = @_;

    my $status = $self->internal_problem();
    return $status->{result}->{problems};
}

1;

__END__

=head1 NAME

Dynatrace Rest API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Set hostname or IP of Dynatrace server (Default: live.dynatrace.com).

=item B<--environment-id>

Set Dynatrace environment ID.

=item B<--port>

Set Dynatrace Port (Default: '443').

=item B<--proto>

Specify http if needed (Default: 'https').

=item B<--api-password>

Set Dynatrace API token.

=item B<--timeout>

Threshold for HTTP timeout (Default: '30').

=back

=cut
