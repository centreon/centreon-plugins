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

package storage::netapp::santricity::restapi::custom::api;

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
            'api-username:s'    => { name => 'api_username' },
            'api-password:s'    => { name => 'api_password' },
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'api-path:s'        => { name => 'api_path' },
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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 8080;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'http';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/devmgr/v2';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '(%{http_code} < 200 or %{http_code} >= 300) and %{http_code} != 424';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_username}) || $self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
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

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{api_username};
    $self->{option_results}->{password} = $self->{api_password};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $content = $self->{http}->request(
        method => defined($options{method}) ? $options{method} : 'GET', 
        url_path => $self->{api_path} . $options{endpoint},
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status},
        cookies_file => '' # in memory
    );

    # code 424 = storageDevice offline
    my $code = $self->{http}->get_code();
    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    return undef if ($code == 424);

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return { $options{name} => $decoded };
}

sub execute_storages_request {
    my ($self, %options) = @_;

    my $storages = $self->request_api(
        name => 'storages',
        endpoint => '/storage-systems'
    );
    return $storages if (!defined($options{endpoints}));

    for (my $i = 0; $i < scalar(@{$storages->{storages}}); $i++) {
        next if (defined($options{filter_name}) && $options{filter_name} ne '' &&
            $storages->{storages}->[$i]->{name} !~ /$options{filter_name}/);

        $storages->{storages}->[$i]->{offline} = 0;

        foreach (@{$options{endpoints}}) {
            my $info = $self->request_api(
                name => 'info',
                endpoint => '/storage-systems/' . $storages->{storages}->[$i]->{wwn} . $_->{endpoint} . (defined($_->{get_param}) ? '?' . $_->{get_param} : '') 
            );
            if (!defined($info)) {
                $storages->{storages}->[$i]->{offline} = 1;
                last;
            }

            $storages->{storages}->[$i]->{ $_->{endpoint} } = defined($info) ? $info->{info} : undef;
        }
    }

    return $storages;
}



1;

__END__

=head1 NAME

Netapp Santricity Rest API

=head1 REST API OPTIONS

Netapp Santricity Rest API

=over 8

=item B<--hostname>

Santricity hostname.

=item B<--port>

Port used (Default: 8080)

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--api-username>

Santricity API username.

=item B<--api-password>

Santricity API password.

=item B<--api-path>

Specify api path (Default: '/devmgr/v2')

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
