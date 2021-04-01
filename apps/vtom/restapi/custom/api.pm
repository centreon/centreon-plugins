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

package apps::vtom::restapi::custom::api;

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
        $options{options}->add_options(arguments =>  {
            'hostname:s@' => { name => 'hostname' },
            'port:s@'     => { name => 'port' },
            'proto:s@'    => { name => 'proto' },
            'username:s@' => { name => 'username' },
            'password:s@' => { name => 'password' },
            'timeout:s@'  => { name => 'timeout' }
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
    $self->{port} = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : 30080;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? shift(@{$self->{option_results}->{proto}}) : 'http';
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
 
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
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub cache_environment {
    my ($self, %options) = @_;
    
    my $has_cache_file = $options{statefile}->read(statefile => 'cache_vtom_env_' . $self->{hostname}  . '_' . $self->{port});
    my $timestamp_cache = $options{statefile}->get(name => 'last_timestamp');
    my $environments = $options{statefile}->get(name => 'environments');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($options{reload_cache_time}) * 60))) {
        $environments = {};
        my $datas = { last_timestamp => time(), environments => $environments };
        my $result = $self->get(path => '/api/environment/list');
        if (defined($result->{result}->{rows})) {
            foreach (@{$result->{result}->{rows}}) {
                $environments->{$_->{id}} = $_->{name};
            }
        }
        $options{statefile}->write(data => $datas);
    }
    
    return $environments;
}

sub cache_application {
    my ($self, %options) = @_;
    
    my $has_cache_file = $options{statefile}->read(statefile => 'cache_vtom_app_' . $self->{hostname}  . '_' . $self->{port});
    my $timestamp_cache = $options{statefile}->get(name => 'last_timestamp');
    my $applications = $options{statefile}->get(name => 'applications');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($options{reload_cache_time}) * 60))) {
        $applications = {};
        my $datas = { last_timestamp => time(), applications => $applications };
        my $result = $self->get(path => '/api/application/list');
        if (defined($result->{result}->{rows})) {
            foreach (@{$result->{result}->{rows}}) {
                $applications->{$_->{id}} = { name => $_->{name}, envSId => $_->{envSId} };
            }
        }
        $options{statefile}->write(data => $datas);
    }
    
    return $applications;
}

sub get {
    my ($self, %options) = @_;

    $self->settings();

    my $response = $self->{http}->request(url_path => $options{path},
                                          critical_status => '', warning_status => '');
    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (defined($content->{errmsg})) {
        $self->{output}->add_option_msg(short_msg => "Cannot get data: " . $content->{errmsg});
        $self->{output}->option_exit();
    }
    
    return $content;
}

1;

__END__

=head1 NAME

VTOM REST API

=head1 SYNOPSIS

VTOM Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

VTOM hostname.

=item B<--port>

Port used (Default: 30080)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--username>

VTOM username.

=item B<--password>

VTOM password.

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
