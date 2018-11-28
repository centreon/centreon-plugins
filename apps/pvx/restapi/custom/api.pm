#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package apps::pvx::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use DateTime;
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
        $options{options}->add_options(arguments => 
                    {
                        "api-key:s"         => { name => 'api_key' },
                        "hostname:s"        => { name => 'hostname' },
                        "url-path:s"        => { name => 'url_path' },
                        "port:s"            => { name => 'port' },
                        "proto:s"           => { name => 'proto' },
                        "credentials"       => { name => 'credentials' },
                        "basic"             => { name => 'basic' },
                        "username:s"        => { name => 'username' },
                        "password:s"        => { name => 'password' },
                        "proxyurl:s"        => { name => 'proxyurl' },
                        "timeout:s"         => { name => 'timeout' },
                        "ssl-opt:s@"        => { name => 'ssl_opt' },
                        "timeframe:s"       => { name => 'timeframe' },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'RESTAPI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};    
    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;

}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    $self->{api_key} = (defined($self->{option_results}->{api_key})) ? $self->{option_results}->{api_key} : undef;
    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/api';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{proxyurl} = (defined($self->{option_results}->{proxyurl})) ? $self->{option_results}->{proxyurl} : undef;
    $self->{ssl_opt} = (defined($self->{option_results}->{ssl_opt})) ? $self->{option_results}->{ssl_opt} : undef;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{credentials} = (defined($self->{option_results}->{credentials})) ? 1 : undef;
    $self->{basic} = (defined($self->{option_results}->{basic})) ? 1 : undef;
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : undef;

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_key}) || $self->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify api-key option.");
        $self->{output}->option_exit();
    }
    
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{proxyurl} = $self->{proxyurl};
    $self->{option_results}->{credentials} = $self->{credentials};
    $self->{option_results}->{basic} = $self->{basic};
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    $self->{http}->add_header(key => 'PVX-Authorization', value => $self->{api_key});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_connection_info {
    my ($self, %options) = @_;
    
    return $self->{hostname} . ":" . $self->{port};
}

sub get_hostname {
    my ($self, %options) = @_;
    
    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;
    
    return $self->{port};
}

sub query_range {
    my ($self, %options) = @_;

    my $data;
    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->epoch;
    my $end_time = DateTime->now->epoch;
    my $uri = URI::Encode->new({encode_reserved => 1});

    my $query = sprintf("%s SINCE %s UNTIL %s", $options{query}, $start_time, $end_time);
    $query .= sprintf(" BY %s", $options{instance}) if (defined($options{instance}) && $options{instance} ne '');
    $query .= sprintf(" WHERE %s", $options{filter}) if (defined($options{filter}) && $options{filter} ne '');
    $query .= sprintf(" FROM %s", $options{from}) if (defined($options{from}) && $options{from} ne '');
    $query .= sprintf(" TOP %s", $options{top}) if (defined($options{top}) && $options{top} ne '');

    $self->{output}->output_add(long_msg => sprintf("Query: '/query?expr=%s'", $query), debug => 1);
    my $result = $self->get_endpoint(url_path => '/query?expr=' . $uri->encode($query));

    return $result->{data};
}

sub get_endpoint {
    my ($self, %options) = @_;

    $self->settings;
    my $response = $self->{http}->request(url_path => $self->{url_path} . $options{url_path});
    
    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    if ($content->{type} eq 'error') {
        $self->{output}->add_option_msg(short_msg => "Cannot get data: " . $content->{error});
        $self->{output}->option_exit();
    }
    
    return $content->{result};
}

1;

__END__

=head1 NAME

PVX REST API

=head1 SYNOPSIS

PVX Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--api-key>

PVX API key.

=item B<--hostname>

PVX hostname.

=item B<--url-path>

PVX url path (Default: '/api')

=item B<--port>

API port (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--username>

Specify username for authentication

=item B<--password>

Specify password for authentication

=item B<--basic>

Specify this option if you access the API over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access the API over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--proxyurl>

Proxy URL if any

=item B<--timeout>

Set HTTP timeout

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => TLSv1" --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE").

=back

=head1 DESCRIPTION

B<custom>.

=cut
