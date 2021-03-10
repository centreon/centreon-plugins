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

package network::cisco::meraki::cloudcontroller::restapi::custom::api;

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
            'hostname:s'                => { name => 'hostname' },
            'port:s'                    => { name => 'port' },
            'proto:s'                   => { name => 'proto' },
            'api-token:s'               => { name => 'api_token' },
            'timeout:s'                 => { name => 'timeout' },
            'reload-cache-time:s'       => { name => 'reload_cache_time' },
            'ignore-permission-errors'  => { name => 'ignore_permission_errors' },
            'use-extra-cache'           => { name => 'use_extra_cache' },
            'reload-extra-cache-time:s' => { name => 'reload_extra_cache_time' },
            'trace-api:s'               => { name => 'trace_api' },
            'api-requests-disabled'     => { name => 'api_requests_disabled' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{cache_checked} = 0;
    $self->{cache_extra_checked} = 0;
    $self->{cached} = {
        updated => 0,
        uplink_statuses => {},
        uplinks_loss_latency => {},
        devices_statuses => {},
        devices_connection_stats => {},
        devices_performance => {},
        devices_clients => {}
    };

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'api.meraki.com';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 180;
    $self->{reload_extra_cache_time} = (defined($self->{option_results}->{reload_extra_cache_time})) ? $self->{option_results}->{reload_extra_cache_time} : 10;
    $self->{ignore_permission_errors} = (defined($self->{option_results}->{ignore_permission_errors})) ? 1 : 0;

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_token}) || $self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-token option.");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{trace_api})) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Time::HiRes',
            error_msg => "Cannot load module 'Time::HiRes'."
        );
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'POSIX',
            error_msg => "Cannot load module 'POSIX'."
        );
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub get_token {
    my ($self, %options) = @_;

    return md5_hex($self->{api_token});
}

sub trace_api {
    my ($self, %options) = @_;

    my $trace_file = $self->{option_results}->{trace_api} ne '' ? $self->{option_results}->{trace_api} : '/tmp/cisco_meraki_plugins.trace';
    open(FH, '>>', $trace_file) or return ;

    my $date_start = POSIX::strftime('%Y%m%d %H:%M:%S', localtime($options{time_start}));
    $date_start .= sprintf('.%03d', ($options{time_start} - int($options{time_start})) * 1000);

    my $time_end = Time::HiRes::time();
    my $date_end = POSIX::strftime('%Y%m%d %H:%M:%S', localtime($time_end));
    $date_end .= sprintf('.%03d', ($time_end - int($time_end)) * 1000);
    print FH "$date_start - $date_end - $$ - $self->{api_token} - $options{url} - $options{code}\n";
    close FH;
}

sub get_shard_hostname {
    my ($self, %options) = @_;

    my $organization_id = $options{organization_id};
    my $network_id = $options{network_id};
    if (defined($options{serial}) && defined($self->{cache_devices}->{ $options{serial} })) {
        $network_id = $self->{cache_devices}->{ $options{serial} }->{networkId};
    }
    if (defined($network_id) && defined($self->{cache_networks}->{$network_id})) {
        $organization_id = $self->{cache_networks}->{$network_id}->{organizationId};
    }

    if (defined($organization_id)) {
        if (defined($self->{cache_organizations}->{$organization_id})
            && $self->{cache_organizations}->{$organization_id}->{url} =~ /^(?:http|https):\/\/(.*?)\//) {
            return $1;
        }
    }

    return undef;
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

sub get_organization {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    my $organization_id;
    if (defined($options{network_id})) {
        $organization_id = $self->{cache_networks}->{ $options{network_id} }->{organizationId};
    }
    my $organization;
    $organization = $self->{cache_organizations}->{$organization_id}
        if (defined($organization_id) && defined($self->{cache_organizations}->{$organization_id}));

    return $organization;
}

sub get_organization_id {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_networks}->{ $options{network_id} }->{organizationId};
}

sub get_cache_devices {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_devices};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{http}->add_header(key => 'X-Cisco-Meraki-API-Key', value => $self->{api_token});
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    return undef if (defined($self->{option_results}->{api_requests_disabled}));

    $self->settings();

    my $hostname = $self->{hostname};
    if (defined($options{hostname})) {
        $hostname = $options{hostname};
    }

    #400: Bad Request- You did something wrong, e.g. a malformed request or missing parameter.
    #403: Forbidden- You don't have permission to do that.
    #404: Not found- No such URL, or you don't have access to the API or organization at all. 
    #429: Too Many Requests- You submitted more than 5 calls in 1 second to an Organization, triggering rate limiting. This also applies for API calls made across multiple organizations that triggers rate limiting for one of the organizations.
    my $time_start;
    while (1) {
        $time_start = Time::HiRes::time() if (defined($self->{option_results}->{trace_api}));
        my $response =  $self->{http}->request(
            hostname => $hostname,
            url_path => '/api/v1' . $options{endpoint},
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );

        my $code = $self->{http}->get_code();
        $self->trace_api(time_start => $time_start, url => $hostname . '/api/v1' . $options{endpoint}, code => $code) 
            if (defined($self->{option_results}->{trace_api}));

        return [] if ($code == 403 && $self->{ignore_permission_errors} == 1);
        return undef if (defined($options{ignore_codes}) && defined($options{ignore_codes}->{$code}));

        if ($code == 429) {
            sleep(1);
            next;
        }

        if ($code < 200 || $code >= 300) {
            $self->{output}->add_option_msg(short_msg => $code . ' ' . $self->{http}->get_message());
            $self->{output}->option_exit();
        }

        my $content;
        eval {
            $content = JSON::XS->new->utf8->allow_nonref(1)->decode($response);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
            $self->{output}->option_exit();
        }

        return ($content);
    }
}

sub cache_meraki_entities {
    my ($self, %options) = @_;

    return if ($self->{cache_checked} == 1);

    $self->{cache_checked} = 1;
    my $has_cache_file = $self->{cache}->read(statefile => 'cache_cisco_meraki_' . $self->get_token());
    my $timestamp_cache = $self->{cache}->get(name => 'last_timestamp');
    $self->{cache_organizations} = $self->{cache}->get(name => 'organizations');
    $self->{cache_networks} = $self->{cache}->get(name => 'networks');
    $self->{cache_devices} = $self->{cache}->get(name => 'devices');

    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{reload_cache_time}) * 60))) {
        $self->{cache_organizations} = $self->get_organizations(
            disable_cache => 1
        );
        $self->{cache_networks} = $self->get_networks(
            organizations => [keys %{$self->{cache_organizations}}],
            disable_cache => 1
        );
        $self->{cache_devices} = $self->get_devices(
            organizations => [keys %{$self->{cache_organizations}}],
            disable_cache => 1
        );

        $self->{cache}->write(data => {
            last_timestamp => time(),
            organizations => $self->{cache_organizations},
            networks => $self->{cache_networks},
            devices => $self->{cache_devices}
        });
    }
}

sub get_organizations {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_organizations} if (!defined($options{disable_cache}) || $options{disable_cache} == 0);
    my $datas = $self->request_api(endpoint => '/organizations');
    my $results = {};
    if (defined($datas)) {
        $results->{$_->{id}} = $_ foreach (@$datas);
    }

    return $results;
}

sub get_networks {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_networks} if (!defined($options{disable_cache}) || $options{disable_cache} == 0);

    my $results = {};
    foreach my $id (keys %{$self->{cache_organizations}}) {
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $id . '/networks',
            hostname => $self->get_shard_hostname(organization_id => $id)
        );
        if (defined($datas)) {
            $results->{ $_->{id} } = $_ foreach (@$datas);
        }
    }

    return $results;
}

sub get_devices {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    return $self->{cache_devices} if (!defined($options{disable_cache}) || $options{disable_cache} == 0);

    my $results = {};
    foreach my $id (keys %{$self->{cache_organizations}}) {
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $id . '/devices',
            hostname => $self->get_shard_hostname(organization_id => $id)
        );
        if (defined($datas)) {
            $results->{ $_->{serial} } = $_ foreach (@$datas);
        }
    }

    return $results;
}

sub filter_organizations {
    my ($self, %options) = @_;

    my $organization_ids = [];
    foreach (values %{$self->{cache_organizations}}) {
        if (!defined($options{filter_name}) || $options{filter_name} eq '') {
            push @$organization_ids, $_->{id};
        } elsif ($_->{name} =~ /$options{filter_name}/) {
            push @$organization_ids, $_->{id};
        }
    }

    return $organization_ids;
}

sub get_networks_connection_stats {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();

    my $timespan = defined($options{timespan}) ? $options{timespan} : 300;
    $timespan = 1 if ($timespan <= 0);

    return $self->request_api(
        endpoint => '/networks/' . $options{network_id} . '/connectionStats?timespan=' . $options{timespan},
        hostname => $self->get_shard_hostname(network_id => $options{network_id}),
        ignore_codes => { 400 => 1 }
    );
}

sub get_networks_clients {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();

    my $timespan = defined($options{timespan}) ? $options{timespan} : 300;
    $timespan = 1 if ($timespan <= 0);

    return $self->request_api(
        endpoint => '/networks/' . $options{network_id} . '/clients?timespan=' . $options{timespan},
        hostname => $self->get_shard_hostname(network_id => $options{network_id}),
        ignore_codes => { 400 => 1 }
    );
}

sub get_organization_device_statuses {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    $self->load_extra_cache();
    return $self->{cached}->{devices_statuses}->{data} if (defined($self->{cached}->{devices_statuses}->{data}));

    $self->{cached}->{updated} = 1;
    $self->{cached}->{devices_statuses} = {
        update_time => time(),
        data => {}
    };
    foreach my $id (keys %{$self->{cache_organizations}}) {
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $id . '/devices/statuses',
            hostname => $self->get_shard_hostname(organization_id => $id)
        );
        foreach (@$datas) {
            $self->{cached}->{devices_statuses}->{data}->{ $_->{serial} } = $_;
            $self->{cached}->{devices_statuses}->{data}->{organizationId} = $id;
        }
    }

    return $self->{cached}->{devices_statuses}->{data};
}

sub get_organization_api_requests_overview {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    my $organization_ids = $self->filter_organizations(filter_name => $options{filter_name});
    my $timespan = defined($options{timespan}) ? $options{timespan} : 300;
    $timespan = 1 if ($timespan <= 0);
    
    my $results = {};
    foreach my $id (@$organization_ids) {
        $results->{$id} = $self->request_api(
            endpoint => '/organizations/' . $id . '/apiRequests/overview?timespan=' . $options{timespan},
            hostname => $self->get_shard_hostname(organization_id => $id)
        );
    }

    return $results;
}

sub get_network_device_connection_stats {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    $self->load_extra_cache();
    my $timespan = defined($options{timespan}) ? $options{timespan} : 300;
    $timespan = 1 if ($timespan <= 0);

    if (!defined($self->{cached}->{devices_connection_stats}->{ $options{network_id} })) {
        $self->{cached}->{updated} = 1;
        $self->{cached}->{devices_connection_stats}->{ $options{network_id} } = {
            update_time => time(),
            data => $self->request_api(
                endpoint => '/networks/' . $options{network_id} . '/wireless/devices/connectionStats?timespan=' . $options{timespan},
                hostname => $self->get_shard_hostname(network_id => $options{network_id})
            )
        };
    }

    my $result;
    foreach (@{$self->{cached}->{devices_connection_stats}->{ $options{network_id} }->{data}}) {
        if ($_->{serial} eq $options{serial}) {
            $result = $_->{connectionStats};
            last;
        }
    }

    return $result;
}

sub get_network_device_uplink {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    $self->load_extra_cache();

    if (!defined($self->{cached}->{uplink_statuses}->{ $options{organization_id} })) {
        $self->{cached}->{updated} = 1;
        $self->{cached}->{uplink_statuses}->{ $options{organization_id} } = {
            update_time => time(),
            data => $self->request_api(
                endpoint => '/organizations/' . $options{organization_id} . '/uplinks/statuses',
                hostname => $self->get_shard_hostname(organization_id => $options{organization_id})
            )
        };
    }

    my $result;
    foreach (@{$self->{cached}->{uplink_statuses}->{ $options{organization_id} }->{data}}) {
        if ($_->{serial} eq $options{serial}) {
            $result = $_->{uplinks};
            last;
        }
    }

    return $result;
}

sub get_device_clients {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    $self->load_extra_cache();
    my $timespan = defined($options{timespan}) ? $options{timespan} : 300;
    $timespan = 1 if ($timespan <= 0);

    if (!defined($self->{cached}->{devices_clients}->{ $options{serial} })) {
        $self->{cached}->{updated} = 1;
        # 400 = feature not supported. 204 = no content
        $self->{cached}->{devices_clients}->{ $options{serial} } = {
            update_time => time(),
            data => $self->request_api(
                endpoint => '/devices/' . $options{serial} . '/clients?timespan=' . $options{timespan},
                hostname => $self->get_shard_hostname(serial => $options{serial})
            )
        };
    }

    return $self->{cached}->{devices_clients}->{ $options{serial} }->{data};
}

sub get_device_switch_port_statuses {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    my $timespan = defined($options{timespan}) ? $options{timespan} : 300;
    $timespan = 1 if ($timespan <= 0);

    return $self->request_api(
        endpoint => '/devices/' . $options{serial} . '/switchPortStatuses?timespan=' . $options{timespan},
        hostname => $self->get_shard_hostname(serial => $options{serial})
    );
}

sub get_network_device_performance {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    $self->load_extra_cache();

    if (!defined($self->{cached}->{devices_performance}->{ $options{serial} })) {
        $self->{cached}->{updated} = 1;
        # 400 = feature not supported. 204 = no content
        $self->{cached}->{devices_performance}->{ $options{serial} } = {
            update_time => time(),
            data => $self->request_api(
                endpoint => '/devices/' . $options{serial} . '/appliance/performance',
                hostname => $self->get_shard_hostname(network_id => $options{network_id}),
                ignore_codes => { 400 => 1, 204 => 1 }
            )
        };
    }

    return $self->{cached}->{devices_performance}->{ $options{serial} }->{data};
}

sub get_organization_uplink_loss_and_latency {
    my ($self, %options) = @_;

    $self->cache_meraki_entities();
    $self->load_extra_cache();

    my $timespan = defined($options{timespan}) ? $options{timespan} : 300;
    $timespan = 1 if ($timespan <= 0);

    if (!defined($self->{cached}->{uplinks_loss_latency}->{ $options{organization_id} })) {
        $self->{cached}->{updated} = 1;
        $self->{cached}->{uplinks_loss_latency}->{ $options{organization_id} } = {
            update_time => time(),
            data => $self->request_api(
                endpoint => '/organizations/' . $options{organization_id} . '/devices/uplinksLossAndLatency?timespan=' . $options{timespan},
                hostname => $self->get_shard_hostname(organization_id => $options{organization_id})
            )
        };
    }

    my $result = {};
    if (defined($self->{cached}->{uplinks_loss_latency}->{ $options{organization_id} }->{data})) {
        foreach (@{$self->{cached}->{uplinks_loss_latency}->{ $options{organization_id} }->{data}}) {
            if ($options{serial} eq $_->{serial}) {
                $result->{ $_->{uplink} } = $_;
            }
        }
    }

    return $result;
}

sub load_extra_cache {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{use_extra_cache}));
    return if ($self->{cache_extra_checked} == 1);

    $self->{cache_extra_checked} = 1;
    my $has_cache_file = $self->{cache}->read(statefile => 'cache_extra_cisco_meraki_' . $self->get_token());
    my $cached = $self->{cache}->get(name => 'cached');
    $self->{cached} = $cached if (defined($cached));
    if (defined($self->{cached}->{devices_statuses}->{update_time}) && ((time() - $self->{cached}->{devices_statuses}->{update_time}) > ($self->{reload_extra_cache_time} * 60))) {
        $self->{cached}->{devices_statuses} = {};
    }

    foreach my $entry (('uplink_statuses', 'uplinks_loss_latency', 'devices_connection_stats', 'devices_performance', 'devices_clients')) {
        next if (!defined($self->{cached}->{$entry}));

        foreach (keys %{$self->{cached}->{$entry}}) {
            if ((time() - $self->{cached}->{$entry}->{$_}->{update_time}) > ($self->{reload_extra_cache_time} * 60)) {
                delete $self->{cached}->{$entry}->{$_};
            }
        }
    }
}

sub close_extra_cache {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{use_extra_cache}));
    if ($self->{cached}->{updated} == 1) {
        $self->{cached}->{updated} = 0;
        $self->{cache}->write(data => { cached => $self->{cached} });
    }
}

1;

__END__

=head1 NAME

Meraki REST API

=head1 SYNOPSIS

api_token Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Meraki api hostname (default: 'api.meraki.com')

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-token>

Meraki api token.

=item B<--timeout>

Set HTTP timeout

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--ignore-permission-errors>

Ignore permission errors (403 status code).

=back

=head1 DESCRIPTION

B<custom>.

=cut
