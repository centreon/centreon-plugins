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

package apps::wazuh::restapi::custom::api;

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
            'hostname:s@' => { name => 'hostname' },
            'username:s@' => { name => 'username' },
            'password:s@' => { name => 'password' },
            'timeout:s@'  => { name => 'timeout' },
            'port:s@'     => { name => 'port' },
            'proto:s@'    => { name => 'proto' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : '';
    $self->{timeout}  = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{port}     = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : 55000;
    $self->{proto}    = (defined($self->{option_results}->{proto})) ? shift(@{$self->{option_results}->{proto}}) : 'https';
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }

    if (!defined($self->{hostname}) ||
        scalar(@{$self->{option_results}->{hostname}}) == 0) {
        return 0;
    }
    return 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    
    if (!defined($self->{option_results}->{ssl_opt})) {
        $self->{option_results}->{ssl_opt} = ['SSL_verify_mode => SSL_VERIFY_NONE'];
    }
    if (!defined($self->{option_results}->{curl_opt})) {
        $self->{option_results}->{curl_opt} = ['CURLOPT_SSL_VERIFYPEER => 0', 'CURLOPT_SSL_VERIFYHOST => 0'];
    }
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(
        url_path => $options{path},
        unknown_status => '', warning_status => '', critical_status => '', 
    );

    if ($self->{http}->get_code() != 200) {
        $self->{output}->add_option_msg(short_msg => 'Connection issue : ' . $self->{http}->get_message() . ' (' . $self->{http}->get_code() . ')');
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json response');
        $self->{output}->option_exit();
    }
    if ($decoded->{error} != 0) {
        $self->{output}->add_option_msg(short_msg => "api error $decoded->{error}: " . $decoded->{message});
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Wazuh REST API

=head1 SYNOPSIS

Wazuh Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Wazuh hostname.

=item B<--username>

Wazuh username.

=item B<--password>

Wazuh password.

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=item B<--proto>

Set protocol (default: 'https')

=item B<--port>

Set HTTP port (default: 55000)

=back

=head1 DESCRIPTION

B<custom>.

=cut
