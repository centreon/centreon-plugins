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

package network::versa::director::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
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
        $options{options}->add_options(arguments =>  {
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'timeout:s'              => { name => 'timeout' },
            'reload-cache-time:s'    => { name => 'reload_cache_time' },
            'ignore-unknown-errors'  => { name => 'ignore_unknown_errors' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{cache_checked} = 0;

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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 9182;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 180;
    $self->{ignore_unknown_errors} = (defined($self->{option_results}->{ignore_unknown_errors})) ? 1 : 0;
    
    my $default_unknown = '(%{http_code} < 200 or %{http_code} >= 300)';
    if ($self->{ignore_unknown_errors} == 1) {
        $default_unknown = '(%{http_code} < 200 or %{http_code} >= 300) and %{http_code} != 404';
    }
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : $default_unknown;
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
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

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_cache_organizations {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_organizations};
}

sub get_cache_networks {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_networks};
}

sub get_cache_devices {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_devices};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{credentials} = 1;
    $self->{option_results}->{basic} = 1;
    $self->{option_results}->{username} = $self->{api_username};
    $self->{option_results}->{password} = $self->{api_password};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub bouchon {
    my ($self, %options) = @_;

    my $content = do {
        local $/ = undef;
        if (!open my $fh, "<", $options{file}) {
            $self->{output}->add_option_msg(short_msg => "Could not open file $options{file} : $!");
            $self->{output}->option_exit();
        }
        <$fh>;
    };

    eval {
        $content = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $content;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $response = $self->{http}->request(
        url_path => $options{endpoint},
        critical_status => $self->{critical_http_status},
        warning_status => $self->{warning_http_status},
        unknown_status => $self->{unknown_http_status}
    );

    my $code = $self->{http}->get_code();
    return [] if ($code == 404 && $self->{ignore_unknown_errors} == 1);

    my $content;
    eval {
        $content = JSON::XS->new->allow_nonref(1)->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return ($content);
}

sub cache_versa_entities {
    my ($self, %options) = @_;

    return if ($self->{cache_checked} == 1);

    $self->{cache_checked} = 1;
    my $has_cache_file = $self->{cache}->read(statefile => 'cache_versa_' . $self->get_hostname());
    my $timestamp_cache = $self->{cache}->get(name => 'last_timestamp');
    $self->{cache_organizations} = $self->{cache}->get(name => 'organizations');
    $self->{cache_appliances} = $self->{cache}->get(name => 'appliances');

    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{reload_cache_time}) * 60))) {
        $self->{cache_organizations} = $self->get_organizations(
            disable_cache => 1
        );
        $self->{cache_appliances} = $self->get_appliances(
            disable_cache => 1
        );

        $self->{cache}->write(data => {
            last_timestamp => time(),
            organizations => $self->{cache_organizations},
            appliances => $self->{cache_appliances}
        });
    }
}

sub get_organizations {
    my ($self, %options) = @_;

    #my $datas = $self->bouchon(file => '/home/qgarnier/clients/plugins/todo/versa/Versa-Centreon/organizations.json');

    $self->cache_versa_entities();
    return $self->{cache_organizations} if (!defined($options{disable_cache}) || $options{disable_cache} == 0);
    my $datas = $self->request_api(endpoint => '/api/config/nms/provider/organizations/organization');

    my $results = { entries => {}, names => { } };

    if (defined($datas->{organization})) {
        foreach (@{$datas->{organization}}) {
            $results->{entries}->{ $_->{uuid} } = $_;
            $results->{names}->{ $_->{name} } = $_->{uuid};
        }
    }

    return $results;
}

sub get_appliances {
    my ($self, %options) = @_;

    #my $datas = $self->bouchon(file => '/home/qgarnier/clients/plugins/todo/versa/Versa-Centreon/appliances.json');

    $self->cache_versa_entities();
    return $self->{cache_appliances} if (!defined($options{disable_cache}) || $options{disable_cache} == 0);
    my $datas = $self->request_api(endpoint => '/api/config/nms/provider/appliances/appliance');

    my $results = { entries => {}, names => { }, types => { } };

    if (defined($datas->{appliance})) {
        foreach (@{$datas->{appliance}}) {
            $results->{entries}->{ $_->{uuid} } = $_;
            $results->{names}->{ $_->{name} } = $_->{uuid};
            $results->{types}->{ $_->{type} } = {} if (!defined($results->{types}->{ $_->{type} }));
            $results->{types}->{ $_->{type} }->{ $_->{name} } = $_->{uuid};
        }
    }

    return $results;
}

sub get_appliances_status_under_organization {
    my ($self, %options) = @_;

    #my $datas = $self->bouchon(file => '/home/qgarnier/clients/plugins/todo/versa/Versa-Centreon/tutu.txt.pretty');

    my $datas = $self->request_api(endpoint => '/vnms/dashboard/tenantDetailAppliances/' . $options{organization});
    return $datas;
}

sub execute {
    my ($self, %options) = @_;

    $self->cache_versa_entities();
    my $results = $self->request_api(
        endpoint => $options{endpoint},
    );

    return $results;
}

1;

__END__

=head1 NAME

Versa Director REST API

=head1 SYNOPSIS

Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Director hostname (Required)

=item B<--port>

Port used (Default: 9182)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-username>

Versa Director API username.

=item B<--api-password>

Versa Director API password.

=item B<--timeout>

Set HTTP timeout

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--ignore-unknown-errors>

Ignore unknown errors (404 status code).

=back

=head1 DESCRIPTION

B<custom>.

=cut
