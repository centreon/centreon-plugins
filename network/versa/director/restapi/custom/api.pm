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
use centreon::plugins::misc;

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
            'ignore-unknown-errors'  => { name => 'ignore_unknown_errors' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'cache-use'              => { name => 'cache_use' }
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
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 9182;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 50;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
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

    # we force to use storable module
    $self->{option_results}->{statefile_storable} = 1;
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
        if (!open my $fh, '<', $options{file}) {
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
        get_param => $options{get_param},
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

sub call_organizations {
    my ($self, %options) = @_;

    #my $datas = $self->bouchon(file => '/home/qgarnier/clients/bpce/Plugin Versa V0/cleans/vnms_organization_orgs.txt');
    my $datas = $self->request_api(
        endpoint => '/vnms/organization/orgs',
        get_param => ['primary=true', 'offset=0', 'limit=200']
    );

    my $orgs = { entries => {}, names => {} };
    foreach (@{$datas->{organizations}}) {
        $orgs->{entries}->{ $_->{uuid} } = {
            uuid => $_->{uuid},
            depth => $_->{depth},
            name => $_->{name},
            globalOrgId => $_->{globalOrgId}
        };
        $orgs->{names}->{ $_->{name} } = $_->{uuid};
    }

    return $orgs;
}

sub call_devices {
    my ($self, %options) = @_;

    #my $datas = $self->bouchon(file => '/home/qgarnier/clients/bpce/Plugin Versa V0/cleans/vnms_appliance_filter.txt');
    my $datas = $self->request_api(
        endpoint => '/vnms/appliance/filter/' . $options{org_name},
        get_param => ['offset=0', 'limit=5000']
    );

    my $devices = { entries => {}, names => {}, types => {} };
    foreach (@{$datas->{appliances}}) {
        $devices->{entries}->{ $_->{uuid} } = {
            uuid => $_->{uuid},
            name => $_->{name},
            ipAddress => $_->{ipAddress},
            type => $_->{type},
            location => $_->{location},
            orgs => $_->{orgs},
            pingStatus => $_->{'ping-status'},
            syncStatus => $_->{'sync-status'},
            servicesStatus => $_->{'services-status'},
            pathStatus => $_->{'path-status'},
            controllerStatus => $_->{'controll-status'},
            alarmSummary => $_->{alarmSummary},
            cpeHealth => $_->{cpeHealth},
            policyViolation => $_->{policyViolation}
        };
        if (defined($_->{Hardware})) {
            $devices->{entries}->{ $_->{uuid} }->{hardware} = {
                memory => $_->{Hardware}->{memory},
                freeMemory => $_->{Hardware}->{freeMemory},
                diskSize => $_->{Hardware}->{diskSize},
                freeDisk => $_->{Hardware}->{freeDisk}
            };
        }
        $devices->{names}->{ $_->{name} } = $_->{uuid};
        $devices->{types}->{ $_->{type} } = {} if (!defined($devices->{types}->{ $_->{type} }));
        $devices->{types}->{ $_->{type} }->{ $_->{name} } = $_->{uuid};
    }

    return $devices;
}

sub call_device_paths {
    my ($self, %options) = @_;

    #my $datas = $self->bouchon(file => '/home/qgarnier/clients/bpce/Plugin Versa V0/cleans/vnms_dashboard_health_path.txt');
    my $datas = $self->request_api(
        endpoint => '/vnms/dashboard/health/path',
        get_param => ['deviceName=' .  $options{device_name}, 'tenantName=' . $options{org_name}, 'offset=0', 'limit=5000']
    );

    my $paths = { org_name => $options{org_name}, device_name => $options{device_name}, entries => []};
    if (defined($datas->[0])) {
        foreach (@{$datas->[0]->{details}}) {
            my $remote_wan_link = centreon::plugins::misc::trim($_->{remoteWanLink});
            my $local_wan_link = centreon::plugins::misc::trim($_->{localWanLink});
            push @{$paths->{entries}}, {
                remoteSiteName => $_->{remoteSiteName},
                localWanLink => $local_wan_link ne '' ? $local_wan_link : 'unknown',
                remoteWanLink => $remote_wan_link ne '' ? $remote_wan_link : 'unknown',
                connState => $_->{connState}
            };
        }
    }

    return $paths;
}

sub cache_organizations {
    my ($self, %options) = @_;

    my $orgs = $self->call_organizations();
    $self->write_cache_file(
        statefile => 'orgs',
        response => $orgs
    );

    return $orgs;
}

sub cache_devices {
    my ($self, %options) = @_;

    my $devices = $self->call_devices(%options);
    $self->write_cache_file(
        statefile => 'devices_' . $options{org_name},
        response => $devices
    );

    return $devices;
}

sub cache_device_paths {
    my ($self, %options) = @_;

    my $paths = $self->call_device_paths(%options);
    $self->write_cache_file(
        statefile => 'device_paths_' . $options{org_name} . '_' . $options{device_name},
        response => $paths
    );

    return $paths;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_versa_' . $self->get_hostname() . '_' . $options{statefile});
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_versa_' . $self->get_hostname() . '_' . $options{statefile});
    my $response = $self->{cache}->get(name => 'response');
    if (!defined($response)) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing');
        $self->{output}->option_exit();
    }
    return $response;
}

sub find_root_organization_name {
    my ($self, %options) = @_;

    foreach (values %{$options{orgs}->{entries}}) {
        return $_->{name} if ($_->{depth} == 1);
    }
}

sub get_organizations {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'orgs')
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_organizations();
}

sub get_devices {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'devices_' . $options{org_name})
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_devices(org_name => $options{org_name});
}

sub get_device_paths {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'device_paths_' . $options{org_name} . '_' . $options{device_name})
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_device_paths(
        org_name => $options{org_name},
        device_name => $options{device_name}
    );
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

=item B<--ignore-unknown-errors>

Ignore unknown errors (404 status code).

=item B<--cache-use>

Use the cache file (created with cache mode). 

=back

=head1 DESCRIPTION

B<custom>.

=cut
