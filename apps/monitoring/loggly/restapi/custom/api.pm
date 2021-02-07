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

package apps::monitoring::loggly::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

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
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port'},
            'proto:s'                => { name => 'proto' },
            'api-password:s'         => { name => 'api_password' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{ssl_opt} = (defined($self->{option_results}->{ssl_opt})) ? $self->{option_results}->{ssl_opt} : undef;
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{ssl_opt} = $self->{ssl_opt};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json;charset=UTF-8');
    $self->{http}->add_header(key => 'Authorization', value => 'bearer ' . $self->{option_results}->{api_password});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(
        %options, 
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub internal_search {
    my ($self, %options) = @_;

    my $status = $self->request_api(
        method => 'GET',
        url_path => '/apiv2/search',
        get_param => [
            'size=1',
            'from=-' . $options{time_period} . 'm',
            'q=' . $options{query}
        ]
    );
    return $status->{rsid}->{id};
}

sub internal_events {
    my ($self, %options) = @_;

    my $status = $self->request_api(
        method => 'GET',
        url_path => '/apiv2/events',
        get_param => ['rsid=' . $options{id}]
    );
    return $status;
}

sub api_events {
    my ($self, %options) = @_;

    my $id = $self->internal_search(
        time_period => $options{time_period},
        query => $options{query}
    );
    my $status = $self->internal_events(id => $id);

    # Get a proper output message
    my $message = '';
    if (length($options{output_field}) && scalar($status->{events}) && defined($status->{events}->[0]->{event})) {
        $message = $status->{events}->[0]->{event};
        for (split /\./, $options{output_field}) {
            if (defined($message->{$_})) {
                $message = $message->{$_};
            } else {
                $message = '';
                last;
            }
        }
    }

    # Message may be messed-up with wrongly encoded characters, let's force some cleanup
    $message =~ s/[\r\n]//g;
    $message =~ s/^\s+|\s+$//g;

    # Clean returned hash
    $status->{message} = $message;
    delete $status->{events};
    delete $status->{page};

    return $status;
}

sub internal_fields {
    my ($self, %options) = @_;

    # 300 limitation comes from the API : https://documentation.solarwinds.com/en/Success_Center/loggly/Content/admin/api-retrieving-data.htm
    my $status = $self->request_api(
        method => 'GET',
        url_path => '/apiv2/fields/' . $options{field} . '/',
        get_param => [
            'facet_size=300',
            'from=-' . $options{time_period} . 'm',
            'q=' . $options{query}
        ]
    );
    return $status;
}

sub api_fields {
    my ($self, %options) = @_;

    my $status = $self->internal_fields(
        time_period => $options{time_period},
        field => $options{field},
        query => $options{query}
    );

    # Fields may be messed-up with wrongly encoded characters, let's force some cleanup
    for (my $i = 0; $i < scalar(@{$status->{ $options{field} }}); $i++) {
        $status->{ $options{field} }->[$i]->{term} =~ s/[\r\n]//g;
        $status->{ $options{field} }->[$i]->{term} =~ s/^\s+|\s+$//g;
    }

    return $status;
}

1;

__END__

=head1 NAME

Loggly Rest API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Set hostname of the Loggly server (<subdomain>.loggly.com).

=item B<--port>

Set Loggly Port (Default: '443').

=item B<--proto>

Specify http if needed (Default: 'https').

=item B<--api-password>

Set Loggly API token.

=item B<--timeout>

Threshold for HTTP timeout (Default: '30').

=back

=cut
