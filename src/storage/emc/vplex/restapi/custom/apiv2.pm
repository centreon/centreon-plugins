#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package storage::emc::vplex::restapi::custom::apiv2;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
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
            'hostname:s'       => { name => 'hostname' },
            'port:s'           => { name => 'port' },
            'proto:s'          => { name => 'proto' },
            'vplex-username:s' => { name => 'vplex_username' },
            'vplex-password:s' => { name => 'vplex_password' },
            'timeout:s'        => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API V2 OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);

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
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{api_username} = defined($self->{option_results}->{vplex_username}) ? $self->{option_results}->{vplex_username} : '';
    $self->{api_password} = defined($self->{option_results}->{vplex_password}) ? $self->{option_results}->{vplex_password} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;

    return $self->{hostname} . '_' . $self->{http}->get_port();
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = {};
    $self->{cache}->write(data => $datas);
    $self->{access_token} = undef;
    $self->{http}->add_header(key => 'Authorization', value => undef);
}

sub get_auth_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'emc_vplex_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{api_username}));
    my $access_token = $self->{cache}->get(name => 'access_token');
    my $expires_on = $self->{cache}->get(name => 'expires_on');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 || !defined($access_token) || (time() > $expires_on) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)) {
        my ($content) = $self->{http}->request(
            method => 'POST',
            hostname => $self->{hostname},
            url_path => '/vplex/v2/token',
            credentials => 1,
            basic => 1,
            username => $self->{api_username},
            password => $self->{api_password},
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{access_token})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{token};
        my $datas = {
            access_token => $access_token,
            expires_on => time() + $decoded->{expiry},
            md5_secret => $md5_secret
        };
        $options{statefile}->write(data => $datas);
    }

    $self->{access_token} = $access_token;
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{access_token})) {
        $self->get_auth_token();
    }

    my $content = $self->{http}->request(
        method => 'GET',
        hostname => $self->{hostname},
        url_path => $options{endpoint},
        get_param => $options{get_param},
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    # Maybe there is an issue with the token. So we retry.
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_token();
        $self->get_auth_token();
        $content = $self->{http}->request(
            method => 'GET',
            hostname => $self->{hostname},
            url_path => $options{endpoint},
            get_param => $options{get_param},
            warning_status => '', unknown_status => '', critical_status => ''
        );
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_cluster_communication {
    my ($self, %options) = @_;

    my $items = $self->request_api(endpoint => '/vplex/v2/cluster_witness');

    return $items->{components};
}

sub get_storage_volumes {
    my ($self, %options) = @_;

    my $clusters = $self->request_api(endpoint => '/vplex/v2/clusters');

    my $results = [];
    foreach my $cluster (@$clusters) {
        my $items = $self->request_api(endpoint => '/vplex/v2/clusters/' . $cluster->{name} . '/storage_volumes');
        foreach my $item (@$items) {
            $item->{cluster_name} = $cluster->{name};
            push @$results, $item;
        }
    }

    return $results;
}

sub get_devices {
    my ($self, %options) = @_;

    my $clusters = $self->request_api(endpoint => '/vplex/v2/clusters');

    my $results = [];
    foreach my $cluster (@$clusters) {
        my $items = $self->request_api(endpoint => '/vplex/v2/clusters/' . $cluster->{name} . '/devices');
        foreach my $item (@$items) {
            $item->{cluster_name} = $cluster->{name};
            push @$results, $item;
        }
    }

    return $results;
}

sub get_fans {
    my ($self, %options) = @_;

    $self->{output}->add_option_msg(short_msg => 'fans information unsupported by rest api v2');
    $self->{output}->option_exit();
}

sub get_psus {
    my ($self, %options) = @_;

    $self->{output}->add_option_msg(short_msg => 'power supplies information unsupported by rest api v2');
    $self->{output}->option_exit();
}

sub get_directors {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/vplex/v2/directors');
}

sub get_distributed_devices {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/vplex/v2/distributed_storage/distributed_devices');
}

1;

__END__

=head1 NAME

VPLEX REST API V2

=head1 SYNOPSIS

Vplex rest api v2

=head1 REST API V2 OPTIONS

=over 8

=item B<--hostname>

API hostname.

=item B<--port>

API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--vplex-username>

API Username.

=item B<--vplex-password>

API Password.

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
