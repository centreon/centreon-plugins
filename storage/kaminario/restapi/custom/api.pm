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

package storage::kaminario::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

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
            'hostname:s@'   => { name => 'hostname' },
            'username:s@'   => { name => 'username' },
            'password:s@'   => { name => 'password' },
            'timeout:s@'    => { name => 'timeout' },
            'resolution:s@' => { name => 'resolution' }
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

    $self->{hostname}   = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{username}   = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : '';
    $self->{password}   = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : '';
    $self->{timeout}    = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{resolution} = (defined($self->{option_results}->{resolution})) ? shift(@{$self->{option_results}->{resolution}}) : '5m';
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{hostname}) ||
        scalar(@{$self->{option_results}->{hostname}}) == 0) {
        return 0;
    }
    return 1;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = 443;
    $self->{option_results}->{proto} = 'https';
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_performance {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(url_path => '/api/v2' . $options{path} . '&__resolution=' . $self->{resolution},
                                        critical_status => '', warning_status => '');
    
    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    
    if ($self->{http}->get_code() != 200) {
        $self->{output}->add_option_msg(short_msg => "Connection issue: " . $decoded->{message});
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

KAMINARIO REST API

=head1 SYNOPSIS

Kaminario Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Kaminario hostname.

=item B<--username>

Kaminario username.

=item B<--password>

Kaminario password.

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=item B<--resolution>

Selected data performance resolution (Default: '5m').

=back

=head1 DESCRIPTION

B<custom>.

=cut
