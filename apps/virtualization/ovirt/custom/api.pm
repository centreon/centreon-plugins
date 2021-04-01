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

package apps::virtualization::ovirt::custom::api;

use strict;
use warnings;
use DateTime;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use URI::Encode;
use Digest::MD5 qw(md5_hex);

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
            'api-username:s'      => { name => 'api_username' },
            'api-password:s'      => { name => 'api_password' },
            'hostname:s'          => { name => 'hostname' },
            'port:s'              => { name => 'port' },
            'proto:s'             => { name => 'proto' },
            'timeout:s'           => { name => 'timeout' },
            'reload-cache-time:s' => { name => 'reload_cache_time' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 180;

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '%{http_code} < 200 or %{http_code} > 400';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
    if (defined($self->{access_token})) {
        $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'ovirt_api_' . md5_hex($self->{hostname}) . '_' . md5_hex($self->{api_username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');

    if ($has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        my $uri = URI::Encode->new({encode_reserved => 1});
        my $encoded_username = $uri->encode($self->{api_username});
        my $encoded_password = $uri->encode($self->{api_password});
        my $post_data = 'grant_type=password' . 
            '&scope=ovirt-app-api' .
            '&username=' . $encoded_username .
            '&password=' . $encoded_password;
        
        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            query_form_post => $post_data,
            url_path => '/ovirt-engine/sso/oauth/token'
        );

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(short_msg => "Authentification endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
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
        if (defined($decoded->{error_code})) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Authentification endpoint returns error code '" . $decoded->{error_code} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = { last_timestamp => time(), access_token => $decoded->{access_token}, expires_on => substr($decoded->{exp}, 0, -3) };
        $options{statefile}->write(data => $datas);
    }
    
    return $access_token;
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    $self->settings();

    $self->{output}->output_add(long_msg => "URL: '" . $self->{proto} . '://' . $self->{hostname} . ':' . $self->{port} .
        $options{url_path} . "'", debug => 1);

    my $content = $self->{http}->request(%options);
    
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
    if (defined($decoded->{error_code})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
        $self->{output}->add_option_msg(short_msg => "API returns error code '" . $decoded->{error_code} . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub list_vms {
    my ($self, %options) = @_;
    
    my $url_path = '/ovirt-engine/api/vms';
    my $response = $self->request_api(method => 'GET', url_path => $url_path);
    
    return $response->{vm};
}

sub list_hosts {
    my ($self, %options) = @_;
    
    my $url_path = '/ovirt-engine/api/hosts';
    my $response = $self->request_api(method => 'GET', url_path => $url_path);
    
    return $response->{host};
}

sub get_host_statistics {
    my ($self, %options) = @_;
    
    my $url_path = '/ovirt-engine/api/hosts/' . $options{id} . '/statistics';
    my $response = $self->request_api(method => 'GET', url_path => $url_path);
    
    return $response->{statistic};
}

sub cache_hosts {
    my ($self, %options) = @_;

    $self->{cache_hosts} = centreon::plugins::statefile->new(%options);
    $self->{cache_hosts}->check_options(option_results => $self->{option_results});
    my $has_cache_file = $self->{cache_hosts}->read(statefile => 'cache_ovirt_hosts_' . md5_hex($self->{hostname}) . '_' . md5_hex($self->{api_username}));
    my $timestamp_cache = $self->{cache_hosts}->get(name => 'last_timestamp');
    my $hosts = $self->{cache_hosts}->get(name => 'hosts');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{reload_cache_time}) * 60))) {
        $hosts = [];
        my $datas = { last_timestamp => time(), hosts => $hosts };
        my $list = $self->list_hosts();
        foreach (@{$list}) {
            push @{$hosts}, { id => $_->{id}, name => $_->{name} };
        }
        $self->{cache_hosts}->write(data => $datas);
    }

    return $hosts;
}

sub list_clusters {
    my ($self, %options) = @_;
    
    my $url_path = '/ovirt-engine/api/clusters';
    my $response = $self->request_api(method => 'GET', url_path => $url_path);
    
    return $response->{cluster};
}

sub list_datacenters {
    my ($self, %options) = @_;
    
    my $url_path = '/ovirt-engine/api/datacenters';
    my $response = $self->request_api(method => 'GET', url_path => $url_path);
    
    return $response->{data_center};
}

1;

__END__

=head1 NAME

oVirt Rest API

=head1 REST API OPTIONS

oVirt Rest API

=over 8

=item B<--hostname>

oVirt hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-username>

oVirt API username.

=item B<--api-password>

oVirt API password.

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
