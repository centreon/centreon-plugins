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

package apps::monitoring::scom::restapi::custom::api;

use base qw(centreon::plugins::mode);

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
            'api-version:s' => { name => 'api_version' },
            'hostname:s'    => { name => 'hostname' },
            'port:s'        => { name => 'port' },
            'proto:s'       => { name => 'proto' },
            'basic'         => { name => 'basic' },
            'ntlmv2'        => { name => 'ntlmv2' },
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

    $self->{api_version} = (defined($self->{option_results}->{api_version})) ? $self->{option_results}->{api_version} : 2016;
    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 80;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = $self->{option_results}->{username};
    $self->{password} = $self->{option_results}->{password};
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{basic} = $self->{option_results}->{basic};
    $self->{ntlmv2} = $self->{option_results}->{ntlmv2};

    if (!defined($self->{api_version}) || $self->{api_version} !~ /(2012|2016|1801)/) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify valid --api-version.');
        $self->{output}->option_exit();
    }
    $self->{api_version} = $1;
    
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
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
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};

    if (defined($self->{username}) && $self->{username} ne '') {
        $self->{option_results}->{credentials} = 1;
        $self->{option_results}->{basic} = 1 if (defined($self->{basic}));
        $self->{option_results}->{ntlmv2} = 1 if (defined($self->{ntlmv2}));
        $self->{option_results}->{username} = $self->{username};
        $self->{option_results}->{password} = $self->{password};
    }
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_method {
    my ($self, %options) = @_;
    
    my $api = 2016;
    $api = 1801 if ($self->{api_version} == 1801); 
    return $self->can($options{method} . '_' . $api);
}

my $map_severity = {
    0 => 'information', 1 => 'warning', 2 => 'critical'
};
my $map_resolution_state = {
    0 => 'new', 255 => 'closed', 254 => 'resolved',
    250 => 'scheduled', 247 => 'awaiting_evidence',
    248 => 'assigned_to_engineering', 
    249 => 'acknowledge',
};

sub get_alerts_2016 {
    my ($self, %options) = @_;

    $self->settings();
    my ($status, $response) = $self->{http}->request(
        url_path => '/api/alerts',
        credentials => 1,
        header => [
            'Accept-Type: application/json; charset=utf-8',
            'Content-Type: application/json; charset=utf-8',
        ],
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status},
    );

    my $entries;
    eval {
        $entries = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    my $results = {};
    foreach (@$entries) { 
        $results->{$_->{alertGenerated}->{id}} = {
            host => $_->{alertGenerated}->{monitoringObjectDisplayName},
            monitoringobjectdisplayname => $_->{alertGenerated}->{monitoringObjectDisplayName},
            resolutionstate => $map_resolution_state->{$_->{alertGenerated}->{resolutionState}},
            name => $_->{alertGenerated}->{name},
            severity => $map_severity->{$_->{alertGenerated}->{severity}},
            timeraised => $_->{alertGenerated}->{timeRaised},
            description => $_->{alertGenerated}->{description},
        };
    }

    return $results;
}

sub get_alerts_1801 {
    my ($self, %options) = @_;

    $self->{output}->add_option_msg(short_msg => "method 'get_alerts_1801' unsupported");
    $self->{output}->option_exit();
}

sub get_alerts {
    my ($self, %options) = @_;

    my $func = $self->get_method(method => 'get_alerts');
    return $func->($self, %options);
}

1;

__END__

=head1 NAME

SCOM Rest API

=head1 CUSTOM MODE OPTIONS

SCOM Rest API

=over 8

=item B<--api-version>

Set SCOM API version (default: 2016).
Could be: 2012, 2016 or 1801.

=item B<--hostname>

Remote hostname or IP address.

=item B<--port>

Port used (Default: 80)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--username>

Specify username for authentication

=item B<--password>

Specify password for authentication

=item B<--basic>

Specify this option if you access webpage over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access webpage over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--ntlmv2>

Specify this option if you access webpage over ntlmv2 authentication (Use with --credentials and --port options)

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
