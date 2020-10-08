#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::graylog::restapi::custom::api;

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
        $options{options}->add_options(arguments =>  {
            'hostname:s'  => { name => 'hostname' },
            'url-path:s'  => { name => 'url_path' },
            'port:s'      => { name => 'port' },
            'proto:s'     => { name => 'proto' },
            'credentials' => { name => 'credentials' },
            'basic'       => { name => 'basic' },
            'username:s'  => { name => 'username' },
            'password:s'  => { name => 'password' },
            'timeout:s'   => { name => 'timeout' },
            'header:s@'   => { name => 'header' },
            'timeframe:s' => { name => 'timeframe' },
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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 9000;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/api/';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{credentials} = (defined($self->{option_results}->{credentials})) ? 1 : undef;
    $self->{basic} = (defined($self->{option_results}->{basic})) ? 1 : undef;
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : 300;
    $self->{step} = (defined($self->{option_results}->{step})) ? $self->{option_results}->{step} : undef;
 
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
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
    $self->{option_results}->{url_path} = $self->{url_path};
    $self->{option_results}->{credentials} = $self->{credentials};
    $self->{option_results}->{basic} = $self->{basic};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
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

sub query_absolute {
    my ($self, %options) = @_;

    my $start_time = DateTime->now->subtract(seconds => $options{timeframe}).'.000';
    $start_time =~ s/T/ /;
    $start_time =~ s/ /%20/;
    my $end_time = DateTime->now.'.000';
    $end_time =~ s/T/ /;
    $end_time =~ s/ /%20/;
    my $uri = URI::Encode->new({encode_reserved => 1});

    my $result = $self->get_endpoint(url_path => 'search/universal/absolute?query=' . $uri->encode($options{query}) .
       '&from=' . $start_time . '&to=' . $end_time . '&limit=1');

    return $result;
}

sub get_endpoint {
    my ($self, %options) = @_;

    $self->settings;
    
    $self->{output}->output_add(long_msg => "Query URL: '" . $self->{proto} . "://" . $self->{hostname} .
        $self->{url_path} . $options{url_path} . "'", debug => 1);

    my $response = $self->{http}->request(url_path => $self->{url_path} . $options{url_path});
    
    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $content;
}

1;

__END__
=head1 NAME

Graylog Rest API

=head1 SYNOPSIS

Graylog Rest API custom mode

=head1 REST API OPTIONS

Graylog Rest API

=over 8

=item B<--timeframe>

Set timeframe in seconds (E.g '300' to check last 5 minutes).

=item B<--hostname>

Graylog hostname.

=item B<--url-path>

API url path (Default: '/api/')

=item B<--port>

API port (Default: 9000)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--credentials>

Specify this option if you access the API with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access the API over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access the API over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--timeout>

Set HTTP timeout

=item B<--header>

Set HTTP header (Can be multiple, example: --header='X-Requested-By: cli')

Useful to check logs on Graylog side

=back

=head1 DESCRIPTION

B<custom>.

=cut
