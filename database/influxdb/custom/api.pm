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

package database::influxdb::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use URI::Encode;
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
            'hostname:s'    => { name => 'hostname' },
            'port:s'        => { name => 'port' },
            'proto:s'       => { name => 'proto' },
            'username:s'    => { name => 'username' },
            'password:s'    => { name => 'password' },
            'timeout:s'     => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MODE OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8086;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    return 0;
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
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};

    if (defined($self->{username}) && $self->{username} ne '') {
        $self->{option_results}->{credentials} = 1;
        $self->{option_results}->{basic} = 1;
        $self->{option_results}->{username} = $self->{username};
        $self->{option_results}->{password} = $self->{password};
    }
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request {
    my ($self, %options) = @_;

    $self->settings();
    
    $self->{output}->output_add(long_msg => "URL: '" . $self->{proto} . '://' . $self->{hostname} . ':'  . $self->{port} . $options{url_path} . "'", debug => 1);
    $self->{output}->output_add(long_msg => "Parameters: '" . join(', ', @{$options{post_param}}) . "'", debug => 1) if (defined($options{post_param}));
    
    my $content = $self->{http}->request(
        %options,
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status},
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }
    
    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{error})) {
        $self->{output}->add_option_msg(short_msg => "API returns error '" . $decoded->{error} . "'");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub query {
    my ($self, %options) = @_;

    my $data;
    foreach my $query (@{$options{queries}}) {
        my $results = $self->request(
            method => 'POST',
            url_path => '/query?epoch=s',
            post_param => ['q=' . $query]
        );

        if (defined($results->{results}[0]->{error})) {
            $self->{output}->add_option_msg(short_msg => "API returns error '" . $results->{results}[0]->{error} . "'");
            $self->{output}->option_exit();
        }
        push @{$data}, @{$results->{results}[0]->{series}} if (defined($results->{results}[0]->{series}));
    }

    return $data;
}

sub compute {
    my ($self, %options) = @_;

    my $result;
    if ($options{aggregation} eq 'average') {
        my $points = 0;
        foreach my $value (@{$options{values}}) {
            $result = 0 if (!defined($result));
            $result += $value->[$options{column}];
            $points++;
        }
        $result /= $points;
    } elsif ($options{aggregation} eq 'minimum') {
        foreach my $value (@{$options{values}}) {
            $result = $value->[$options{column}] if (!defined($result) || $value->[$options{column}] < $result);
        }
    } elsif ($options{aggregation} eq 'maximum') {
        foreach my $value (@{$options{values}}) {
            $result = $value->[$options{column}] if (!defined($result) || $value->[$options{column}] > $result);
        }
    } elsif ($options{aggregation} eq 'sum') {
        foreach my $value (@{$options{values}}) {
            $result = 0 if (!defined($result));
            $result += $value->[$options{column}];
        }
    }

    return $result;
}

1;

__END__

=head1 NAME

InfluxDB Rest API

=head1 CUSTOM MODE OPTIONS

InfluxDB Rest API

=over 8

=item B<--hostname>

Remote hostname or IP address.

=item B<--port>

Port used (Default: 8086)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--username>

Specify username for authentication.

=item B<--password>

Specify password for authentication.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=item B<--unknown-http-status>

Threshold unknown for http response code.
(Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-http-status>

Threshold warning for http response code.

=item B<--critical-http-status>

Threshold critical for http response code.

=back

=head1 DESCRIPTION

B<custom>.

=cut
