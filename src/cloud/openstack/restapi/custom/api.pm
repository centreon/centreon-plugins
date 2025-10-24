#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_encode json_decode value_of is_excluded flatten_arrays is_local_ip/;
use Digest::MD5 qw(md5_hex);
use DateTime::Format::Strptime;

# Shortcut to define all identification options for a service
sub _service_ident_options {
    my (%options) = @_;
    my $type = $options{type};

    ( $type.'-url:s'      => { name => $type.'_url', default => '' },
      $type.'-hostname:s' => { name => $type.'_hostname', default => '' },
      $type.'-proto:s'    => { name => $type.'_proto', default => 'https' },
      $type.'-port:s'     => { name => $type.'_port', default => $options{port} // '' },
      $type.'-endpoint:s' => { name => $type.'_endpoint', default => $options{endpoint} // '' },
      $type.'-insecure'   => { name => $type.'_insecure', default => '0' },
      $type.'-timeout:s'  => { name => $type.'_timeout' }
    )
}

# Shortcut to define all filter options for a service
sub _service_filters_options {
    my (%options) = @_;
    my $type = $options{type};
    (
      'include-'.$type.'-name:s@' => { name => 'include_'.$type.'_name', },
      'exclude-'.$type.'-name:s@' => { name => 'exclude_'.$type.'_name', },
      'include-'.$type.'-type:s@' => { name => 'include_'.$type.'_type', },
      'exclude-'.$type.'-type:s@' => { name => 'exclude_'.$type.'_type', },
      'include-'.$type.'-id:s@'   => { name => 'include_'.$type.'_id', },
      'exclude-'.$type.'-id:s@'   => { name => 'exclude_'.$type.'_id', }
    )
}

# All caches used by this connector
# authent => contains authentication token and the service catalog list
# flavor => contains flavor id to name mapping
# image => contains image id to name mapping
my @_caches = ('authent', 'flavor', 'image');

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    unless ($options{output}) {
        warn "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};
    $options{options}->add_options(arguments => {
        # Default connection options
        'hostname:s'        => { name => 'hostname', default => '' },
        'proto:s'           => { name => 'proto', default => 'http' },
        'insecure'          => { name => 'insecure', default => 0 },
        'timeout:s'         => { name => 'timeout', default => 10 },

        # Declarations of all mandatory services
        'disco-mode:s'      => { name => 'disco_mode', default => 'auto' },
        _service_ident_options(type => 'identity', port => 5000, endpoint => '/v3'),
        _service_filters_options(type => 'filter', ),
        _service_ident_options(type => 'compute',  port => 8774, endpoint => '/v2.1'),
        _service_filters_options(type => 'compute', ),
        _service_ident_options(type => 'image',    port => 9292, endpoint => ''),
        _service_filters_options(type => 'image', ),
        _service_ident_options(type => 'volume',   port => 9292, endpoint => ''),
        _service_filters_options(type => 'volume', ),

        # Endpoint filters common to all services
        _endpoint_filters_options(),

        # Authentication parameters
        'username:s'          => { name => 'username', default => '' },
        'password:s'          => { name => 'password', default => '' },
        'user-domain-id:s'    => { name => 'user_domain_id', default => 'default' },
        'project-name:s'      => { name => 'project_name', default => 'demo' },
        'project-domain-id:s' => { name => 'project_domain_id', default => 'default' },
        'authent-by-env:s'    => { name => 'authent_by_env', default => '0' },
        'authent-by-file:s'   => { name => 'authent_by_file', default => '' } }
   ) unless $options{noptions};

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    # Create all cache files
    foreach (@_caches) {
        $self->{'cache_'.$_} = centreon::plugins::statefile->new(%options);
        $self->{'cache_'.$_.'_content'} = {};
    }

    $self->{token} = '';

    return $self;
}

# Apply defaults include/exclude filters for a service
sub service_check_filters {
    my ($self, %options) = @_;
    my $type = $options{type};

    foreach ('include_'.$type.'_name', 'exclude_'.$type.'_name',
             'include_'.$type.'_type', 'exclude_'.$type.'_type',
             'include_'.$type.'_id', 'exclude_'.$type.'_id') {
        $self->{$_} = $self->{option_results}->{$_} // [ ];
    }

    # Mandatory services (identity, compute, image...) have a default type unless overridden by user
    $self->{'include_'.$type.'_type'} = [ '^'.$type.'v?\d?$' ]
        if $options{mandatory} && not @{$self->{'include_'.$type.'_type'}};
}

# Validate service declaration options and construct the 'service_url' connection string
sub service_check_options {
    my ($self, %options) = @_;

    my $service = $options{type}.'_';

    $self->{$service.$_} = $self->{option_results}->{$service.$_}
        foreach qw/url insecure endpoint port interface timeout/;
    # Add default endpoint to URL if defined and not already present
    $self->{$service.'url'} .= $self->{$service.'endpoint'}
        if $self->{$service.'url'} ne '' && $self->{$service.'endpoint'} ne '' && $self->{$service.'url'} !~ /$self->{$service.'endpoint'}$/;

    $self->service_check_filters(%options);

    if ($options{type} ne 'identity' && $options{keystone_services} && $self->{disco_mode} =~ /(?:auto|keystone)/) {
        # For all services except Keystone/identity the URL is retrieved from
        # the Keystone catalog unless disco_mode is set to 'manual'
        KEYSTONE_CATALOG: foreach my $keystone_service (@{$options{keystone_services}}) {
            next if $self->is_excluded_service(type => $options{type}, service => $keystone_service);

            foreach my $endpoint (@{$keystone_service->{endpoints}}) {
                next if $self->is_excluded_endpoint($endpoint);
                $self->{$service.'url'} = $endpoint->{url};
                last KEYSTONE_CATALOG
            }
       }
    }
    if ($self->{$service.'url'} eq '' && ($options{type} eq 'identity' || $self->{disco_mode} =~ /(?:auto|manual)/)) {
        # For Keystone/identity and other services when no URL is already available and disco_mode is
        # not 'keystone' the URL is resolved from command line parameters
        my %desc;
        $desc{$_} = $self->{option_results}->{$_}
            foreach qw/proto port hostname/;

        foreach (qw/hostname proto timeout/) {
            $desc{$_} = $self->{option_results}->{$service.$_}
                if $self->{option_results}->{$service.$_};
        }
        $self->{$service.'url'} = $desc{proto}.'://'.$desc{hostname}.':'.$self->{$service.'port'}.$self->{$service.'endpoint'};
    }

    my $invalid_url = $options{mandatory} && $self->{$service.'url'} !~ /^(https?:\/\/[^:][-\.\w:]+)/;
    if ($options{type} eq 'identity') {
        # A valid keystone URL is always required since it is the authentication service
        # First part of Keystone URL is also used to define cache filename

        $self->{output}->option_exit(short_msg => 'A valid --'.$options{type}."-url option is '$service' required=> ".$self->{$service.'url'} )
            if $invalid_url;
        $self->{identity_base_url} = $1;
    } else {
        # A valid URL is also required for mandatory services
        #
        $self->{output}->option_exit(short_msg => "Cannot retrieve $options{type} service URL")
            if $invalid_url;
    }

    $self->{$service.'insecure'} = $self->{insecure}
        unless $self->{$service.'insecure'};

    # define endpoint filters options
    $self->{$_} = flatten_arrays($self->{option_results}->{$_}) foreach qw/include_endpoint_region exclude_endpoint_region
                                                                           include_endpoint_region_id exclude_endpoint_region_id
                                                                           include_endpoint_interface exclude_endpoint_interface/;
}

# Shortcut to check if a service is excluded based on its type, name or id
sub is_excluded_service
{
    my ($self, %options) = @_;
    my $type = $options{type};
    my $service = $options{service};

    is_excluded($service->{type}, $self->{'include_'.$type.'_type'}, $self->{'exclude_'.$type.'_type'}) ||
        is_excluded($service->{name}, $self->{'include_'.$type.'_name'}, $self->{'exclude_'.$type.'_name'}) ||
        is_excluded($service->{id}, $self->{'include_'.$type.'_id'}, $self->{'exclude_'.$type.'_id'});
}

# Shortcut to check if an endpoint is excluded based on its interface, region or region_id
sub is_excluded_endpoint
{
    my ($self, $endpoint) = @_;

    is_excluded($endpoint->{interface}, $self->{include_endpoint_interface}, $self->{exclude_endpoint_interface}) ||
        is_excluded($endpoint->{region}, $self->{include_endpoint_region}, $self->{exclude_endpoint_region}) ||
        is_excluded($endpoint->{region_id}, $self->{include_endpoint_region_id}, $self->{exclude_endpoint_region_id});
}

# Shortcut to define all filter options for service endpoints
sub _endpoint_filters_options {
    my (%options) = @_;
    ( 'include-endpoint-id:s@'        => { name => 'include_endpoint_id' },
      'exclude-endpoint-id:s@'        => { name => 'exclude_endpoint_id' },
      'include-endpoint-region:s@'    => { name => 'include_endpoint_region' },
      'exclude-endpoint-region:s@'    => { name => 'exclude_endpoint_region' },
      'include-endpoint-region-id:s@' => { name => 'include_endpoint_region_id' },
      'exclude-endpoint-region-id:s@' => { name => 'exclude_endpoint_region_id' },
      'include-endpoint-interface:s@' => { name => 'include_endpoint_interface' },
      'exclude-endpoint-interface:s@' => { name => 'exclude_endpoint_interface' }
    )
}

# Mapping between some OptnStack environment variables and our options
my %_external_conf_equiv = ( OS_USERNAME => 'username',
                             OS_PASSWORD => 'password',
                             OS_PROJECT_DOMAIN_ID => 'project_domain_id',
                             OS_USER_DOMAIN_ID => 'user_domain_id',
                             OS_PROJECT_NAME => 'project_name',
                             OS_AUTH_URL => 'identity_url',
                           );

sub apply_external_conf {
    my ($self, %options) = @_;

    # Some options can be taken from OpenStack environement variables already defined or
    # taken from a file that has been generated for OpenStack CLI tools
    # Please refer to https://docs.openstack.org/liberty/install-guide-ubuntu/keystone-openrc.html
    # for more details about those variables

    if ($options{apply_conf_from_env}) {
        foreach (keys %_external_conf_equiv) {
            $self->{$_external_conf_equiv{$_}} = $ENV{$_}
                if exists $ENV{$_};
        }
    }

    if ($options{apply_conf_from_file}) {
        open(my $file, "<".$options{apply_conf_from_file})
            or $self->{output}->option_exit(short_msg => "Cannot open file '".$options{apply_conf_from_file}."': $!");
        foreach my $line (<$file>) {
            next unless $line =~ /^[\s\t]*export[\t\s]+(\w+)=["']?(.*?)["']?$/;

            # Only handle variables defined using 'export variable="value"'
            $self->{$_external_conf_equiv{$1}} = $2
                if exists $_external_conf_equiv{$1};
        }
        close($file);
    }
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    # Init caches
    $self->{$_}->check_options(option_results => $self->{option_results})
        foreach qw/cache_authent cache_flavor cache_image/;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/authent_by_env authent_by_file disco_mode user_domain_id project_name project_domain_id username password insecure proto hostname timeout/;

    $self->{output}->option_exit(short_msg => 'Invalid --disco-mode values: '.$self->{disco_mode}.' ( auto, manual, keystone )')
        unless $self->{disco_mode} =~ /^(?:auto|manual|keystone)$/;

    # Defines connection parameters for mandatory identity service
    $self->service_check_options(mandatory => 1, type => 'identity');

    $self->apply_external_conf(apply_conf_from_env => $self->{authent_by_env},
                               apply_conf_from_file => $self->{authent_by_file});

    foreach ('password', 'username') {
        $self->{output}->option_exit(short_msg => "Need to specify --$_ option.")
            if $self->{$_} eq '';
    }

    # Define base cache filename based on Keystone URL
    $self->{keystone_cache_filename} = 'openstack_restapi_keystone_'.md5_hex(lc $self->{identity_base_url}.'##'.$self->{project_name}.'##'.$self->{username}).'_';
    return 0;
}

sub other_services_check_options {
    my ($self, %options) = @_;

    my $catalog = $options{keystone_services};

    # Define connection parameters for each services
    $self->service_check_options(mandatory => 1, type => 'compute', keystone_services => $catalog );
    $self->service_check_options(mandatory => 1, type => 'image', keystone_services => $catalog );
    $self->service_check_options(mandatory => 1, type => 'volume',  keystone_services => $catalog );
}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->set_options(%{$self->{option_results}});
}

sub connect_info {
    my ($self, %options) = @_;

    my $url = $options{url};

    ( full_url => $url.($options{resource} // ''), proto=> $url =~ s/^(https?).+/$1/r )
}

# Returns Instances list by calling Nova service
sub nova_list_instances {
    my ($self, %options) = @_;

    my $limit = 200;
    my %params = ( limit => $limit );
    $params{project_id} = $options{project_id}
        if $options{project_id};

    my $token = $options{token} || $self->{token};

    # Nova natively accepts certain filters but only one of each is allowed and they cannot be
    # regular expressions. We use our filters that satisfy these requirements
    foreach my $filter ('name', 'status', 'image', 'flavor', 'host') {
        my $data = value_of(\%options, "->{include_".$filter."}->[0]", '');
        next unless $data =~ /^[\w\s]+$/;

        $params{$filter}=$data;
    }

    my $response_brut;
    my @results;

    # Retry to handle token expiration
    while (1) {
        $response_brut = $self->{http}->request(
            method => 'GET',
            get_params => \%params,
            header => [ 'Content-Type: application/json',
                        'X-Auth-Token: '.$token],
            $self->connect_info(url => $self->{compute_url}, resource => '/servers/detail'),
            insecure => $self->{compute_insecure},
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );

        my $response = json_decode($response_brut);

        return { http_status => $self->{http}->get_code(),message => value_of($response, "->{error}->{title}", 'Bad request').': '.value_of($response, "->{error}->{message}", "Invalid response") }
            if ref $response ne 'HASH' || $response->{error} || not $response->{servers};

        last unless @{$response->{servers}};
        $params{marker} = $response->{servers}[-1]->{id};

        NOVA_SERVERS: foreach my $server (@{$response->{servers}}) {
            next if is_excluded($server->{name}, $options{include_name}, $options{exclude_name});
            next if is_excluded($server->{id}, $options{include_id}, $options{exclude_id});
            next if is_excluded($server->{status}, $options{include_status}, $options{exclude_status});
            next if is_excluded($server->{'OS-EXT-STS:vm_state'} // '', $options{include_vm_state}, $options{exclude_vm_state});
            next if is_excluded($server->{'OS-EXT-SRV-ATTR:instance_name'} // '', $options{include_instance_name}, $options{exclude_instance_name});
            next if is_excluded($server->{'OS-EXT-SRV-ATTR:host'} // '', $options{include_host}, $options{exclude_host});
            next if is_excluded($server->{'OS-EXT-AZ:availability_zone'} // '', $options{include_zone}, $options{exclude_zone});

            my @ips;
            foreach my $adresses (values %{$server->{addresses}}) {
                foreach my $network (@{$adresses}) {

                    next NOVA_SERVERS if is_excluded($network->{addr}, $options{include_ip}, $options{exclude_ip});

                    push @ips, $network->{addr};
                }
            }
            next NOVA_SERVERS if $options{exclude_no_ip} && not @ips;

            @ips = reverse sort { is_local_ip($a) <=> is_local_ip($b) } @ips;

            my $flavor = value_of($server, '->{flavor}->{id}');
            $flavor = $self->nova_get_flavor_label(flavor_id => $flavor) || $flavor;
            my $image = value_of($server, '->{image}->{id}');
            $image = $self->glance_get_image_label(image_id => $image) || $image;

            next if is_excluded($flavor, $options{include_flavor}, $options{exclude_flavor});
            next if is_excluded($image, $options{include_image}, $options{exclude_image});

            my $items = { id => $server->{id},
                          host => $server->{'OS-EXT-SRV-ATTR:host'} // 'N/A',
                          name => $server->{name},
                          instance_name => $server->{'OS-EXT-SRV-ATTR:instance_name'} // 'N/A',
                          zone => $server->{'OS-EXT-AZ:availability_zone'} // 'N/A',
                          vm_state => $server->{'OS-EXT-STS:vm_state'} // 'N/A',
                          status => $server->{status},
                          image => $image || 'N/A',
                          flavor => $flavor || 'N/A',
                          ip => @ips ? $ips[0] : 'N/A',
                          ips => \@ips,
                          bookmark => '',
                          href => '',
                          project_id => $server->{tenant_id}
                        };

            foreach my $href (@{$server->{links}}) {
                if ($href->{rel} eq 'bookmark') {
                    $items->{bookmark} = $href->{href};
                } elsif ($href->{rel} eq 'self') {
                    $items->{href} = $href->{href};
                }
            }

            push @results, $items;
        }

        last if @{$response->{servers}} < $limit;
    }

    return { http_status => 200, results => \@results }
}

# Returns image label from id by calling Glance service
# Uses a cache file to limit API calls
sub glance_get_image_label {
    my ($self, %options) = @_;

    my $id = $options{image_id} // '';
    return $self->{cache_image_content}->{$id} if exists $self->{cache_image_content}->{$id};

    $self->{cache_image}->read(statefile => $self->{keystone_cache_filename}.'image');
    my $cache_image_data = $self->{cache_image}->{datas};

    if (value_of($cache_image_data, '->{expires_at}', 0) - 60 < time() ||
        not exists $cache_image_data->{$id}) {

        my $token = $options{token} || $self->{token};
        my $response_brut = $self->{http}->request(
            method => 'GET',
            header => [ 'X-Auth-Token: '. $token,
                        'Content-Type: application/json' ],
            $self->connect_info(url => $self->{image_url}, resource => '/v2/images'),
            insecure => $self->{image_insecure},

            silently_fail => 1,
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );

        my $response = json_decode($response_brut, output => $self->{output}, no_exit => 1);
        return '' if ref $response ne 'HASH' || not exists $response->{images};

        $cache_image_data = { expires_at => time() + 3600 };

        $cache_image_data->{ $_->{id} } = $_->{name} foreach @{$response->{images}};

        $self->{cache_image}->write(data => $cache_image_data);
    }
    $self->{cache_image_content} = $cache_image_data;

    return $self->{cache_image_content}->{$id} // '';
}

# Returns flavor label from id by calling Nova service
# Uses a cache file to limit API calls
sub nova_get_flavor_label {
    my ($self, %options) = @_;

    my $id = $options{flavor_id} // '';
    return $self->{cache_flavor_content}->{$id} if exists $self->{cache_flavor_content}->{$id};

    $self->{cache_flavor}->read(statefile => $self->{keystone_cache_filename}.'flavor');
    my $cache_flavor_data = $self->{cache_flavor}->{datas};

    if (value_of($cache_flavor_data, '->{expires_at}', 0) - 60 < time() ||
        not exists $cache_flavor_data->{$id}) {

        my $token = $options{token} || $self->{token};
        my $response_brut = $self->{http}->request(
            method => 'GET',
            header => [ 'X-Auth-Token: '. $token,
                        'Content-Type: application/json' ],
            $self->connect_info(url => $self->{compute_url}, resource => '/flavors'),
            insecure => $self->{compute_insecure},

            silently_fail => 1,
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );

        my $response = json_decode($response_brut, output => $self->{output}, no_exit => 1);

        return '' if ref $response ne 'HASH' || not exists $response->{flavors};

        $cache_flavor_data = { expires_at => time() + 3600 };

        $cache_flavor_data->{ $_->{id} } = $_->{name} foreach @{$response->{flavors}};

        $self->{cache_flavor}->write(data => $cache_flavor_data);
    }
    $self->{cache_flavor_content} = $cache_flavor_data;

    return $self->{cache_flavor_content}->{$id} // '';
}

# Authenticate to Keystone service
# Keystone also returns service list endpoints
sub keystone_authent {
    my ($self, %options) = @_;

    $self->settings();

    $self->{cache_authent}->read(statefile => $self->{keystone_cache_filename}.'authent');
    my $cache_authent_data = $self->{cache_authent}->{datas};

    if (!$options{dont_read_cache} && ref $cache_authent_data eq 'HASH' && $cache_authent_data->{token} && $cache_authent_data->{expires_at} -60 < time()) {
        $self->{token} = $cache_authent_data->{token};
        return $cache_authent_data;
    }

    my $query = {
        auth => {
            identity => {
                methods => ['password'],
                password => {
                    user => {
                        name => $self->{username},
                        domain => { id => $self->{user_domain_id} },
                        password => $self->{password}
                    }
                }
            },
            scope => {
                project => {
                    domain => { id => $self->{project_domain_id} },
                    name => $self->{project_name},
                }
            }
        }
    };
    $query = json_encode($query);

    my $response_brut = $self->{http}->request(
        method => 'POST',
        header => ['Content-Type: application/json'],
        $self->connect_info(url => $self->{identity_url}, resource => '/auth/tokens'),
        insecure => $self->{identify_insecure},

        query_form_post => $query,

        critical_status => '',
        warning_status => '',
        unknown_status => ''
    );

    my $response = json_decode($response_brut, output => $self->{output}, no_exit => 1);

    if (ref $response ne 'HASH' || $response->{error} || not $response->{token}) {
        return { token => '', expires_at => 0, services => [] }
            if $options{discover_mode};

        $self->{output}->option_exit(short_msg => value_of($response, "->{error}->{title}", 'Bad request').': '.value_of($response, "->{error}->{message}", "Unknown error"));
    }

    my $token = $self->{http}->get_header(name => 'X-Subject-Token');

    $self->{output}->option_exit(short_msg => 'Bad request: Cannot find X-Subject-Token header')
        unless $token;
    my $expires_at = DateTime::Format::Strptime->new(
        pattern  => "%Y-%m-%dT%H:%M:%S.%N%Z",
        on_error => "undef"
    );
    $expires_at = $expires_at->parse_datetime($response->{token}->{expires_at});
    $expires_at = $expires_at->epoch();

    my %data = ( token => $token,
                 expires_at => $expires_at,
                 services => $response->{token}->{catalog}
               );

    $self->{cache_authent}->write(data => \%data);

    $self->{token} = $token;

    return \%data;
}

# Extra suffix to append to the endpoint URL for service health check
# Goal is to get a small response who requires authentication token
my %_endpoint_suffix = ( 'volumev2' => '/volumes?limit=1',
                         'volumev3' => '/volumes?limit=1',
                         'image'    => '/v2/images?limit=1',
                         'compute'  => '/v2.1',
                         'placement'=> '',
                         'identity' => '' );

# Horizon returns a HTML web page not JSON, so we check that it contains those strings
my %_expected_data = ( 'horizon'    => 'OpenStack Dashboard',
                       'dashboard'  => 'OpenStack Dashboard' );

sub ping_service
{
    # Heath check of an OpenStack service
    # We test HTTP status code and the content of the data returned by the service
    # (is valid JSON or that it contains specific strings).
    my ($self, %options) = @_;

    $options{$_} //= '' foreach qw/endpoint_suffix expected_data/;

    my $token = $options{token} || $self->{token};
    my $service_url = $options{service_url};

    my $endpoint_suffix = $options{endpoint_suffix} eq 'auto' ?
                            $_endpoint_suffix{$options{type}} // '' :
                            $options{endpoint_suffix} eq 'none' ?
                                '' :
                                $options{endpoint_suffix};

    $service_url .= $endpoint_suffix
            if $endpoint_suffix ne '' && $service_url !~ /\Q$endpoint_suffix\E$/;

    my $expected_data = '';
    if ($options{expected_data} eq 'auto') {
        $expected_data = $_expected_data{$options{type}} // '';
    } elsif ($options{expected_data} ne '') {
        $expected_data = $options{expected_data};
    }

    my $response_brut = eval {$self->{http}->request(
        method => 'GET',
        $self->connect_info(url => $service_url),
        insecure => $options{insecure} || 0,
        silently_fail => 1,
        header => [ 'X-Auth-Token: '.$token,
                    'Content-Type: application/json' ],
        critical_status => '',
        warning_status => '',
        unknown_status => ''
    ) };

    my $valid;
    if ($expected_data ne '') {
        $valid = $response_brut =~ /$expected_data/ ? 1 : 0;
    } else {
        $valid = json_decode($response_brut, silence => 1) ? 1 : 0;
    }
    my $data = { http_status => $self->{http}->get_code(),
                 http_status_message => $self->{http}->get_message(),
                 valid_content => $valid
    };

    return $data;
}

1;

__END__

=head1 NAME

Openstack REST API

=head1 SYNOPSIS

Openstack Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--username>

OpenStack username.

=item B<--password>

OpenStack password.

=item B<--user-domain>

OpenStack user domain to use with authentication (default: 'default').

=item B<--project-name>

OpenStack project name to use with authentication (default: 'demo').

=item B<--project-domain>

OpenStack project domain to use with authentication (default: 'default').

=item B<--timeout>

Set HTTP timeout in seconds (default: '10').
This timeout will only be used for other services if a more specific one is not already defined with other options.

=item B<--insecure>

Allow insecure TLS connection (default: '0').
This value will only be used for other services if a more specific one is not already defined with other options.

=item B<--authent-by-env>

Set to 1 to use OpenStack environment variables if they are defined (default: 0).
Used environment variables are OS_USERNAME, OS_PASSWORD, OS_PROJECT_DOMAIN, OS_USER_DOMAIN, OS_PROJECT_NAME, OS_AUTH_URL.

=item B<--authent-by-file>

Read OpenStack environment variables from a file.
Handled environment variables are OS_USERNAME, OS_PASSWORD, OS_PROJECT_DOMAIN, OS_USER_DOMAIN, OS_PROJECT_NAME, OS_AUTH_URL.
Those variables must be defined using 'export VARIABLE="value"' syntax.

=item B<--hostname>

Set default OpenStack service hostname. This hostname will only be used for other services if a more specific one is not already defined with other options.

=item B<--proto>

Set default protocol to use (default: 'https').
This protocol will only be used for other services if a more specific one is not already defined with other options.

=item B<--disco-mode>

Specifies how OpenStack service endpoints are discovered.
Can be 'auto' (default), 'manual' or 'keystone'.
With 'auto' mode services endpoints are retrieved from Keystone catalog except if a specific URL is provided with other options.
With 'keystone' mode services endpoints are only retrieved from Keystone catalog.
With 'manual' mode services endpoints are retrieved from command line options.

=item B<--identity-url>

Set the URL to use for the OpenStack Keystone (identity) service.
A valid Keystone URL is required since it is the authentication service.
The first part of the Keystone URL is also used to define the cache filename.

Example: C<--identity-url="https://myopenstack.local:5000">

This URL can also be construct with options (--identity-hostname, --identity-proto, --identity-port, --identity-endpoint).

=item B<--identity-hostname>

Set the hostname part of the Keystone service URL.

=item B<--identity-proto>

Set the protocol to use in the Keystone service URL (default: 'https').

=item B<--identity-port>

Set the port to use in the Keystone service URL (default: 5000).

=item B<--identity-endpoint>

Set the endpoint to use in the Keystone service URL (default: '/v3').

=item B<--identity-insecure>

Allow insecure TLS connection (default: '0').
When set to 0 the default insecure value passed with --insecure is used.

=item B<--identity-timeout>

Set HTTP timeout in seconds (default: '0').
When set to 0 the default timeout value passed with --timeout is used.

=item B<--compute-url>

Set the URL to use for the OpenStack Nova (compute) service.
A valid Nova URL is required since it is a mandatory service.
Nova URL is retrieved from Keystone catalog unless disco-mode is set to 'manual' or a specific URL is provided with this option.

Example: C<--compute-url="https://myopenstack.local:8774">

This URL can also be construct with options (--compute-hostname, --compute-proto, --compute-port, --compute-endpoint).

=item B<--compute-hostname>

Set the hostname part of the Nova service URL.

=item B<--compute-proto>

Set the protocol to use in the Nova service URL (default: 'https').

=item B<--compute-port>

Set the port to use in the Nova service URL (default: 8774).

=item B<--compute-endpoint>

Set the endpoint to use in the Nova service URL (default: '/v2.1').

=item B<--compute-insecure>

Allow insecure TLS connection (default: '0').
When set to 0 the default insecure value passed with --insecure is used.

=item B<--compute-timeout>

Set HTTP timeout in seconds (default: '0').
When set to 0 the default timeout value passed with --timeout is used.

=item B<--image-url>

Set the URL to use for the OpenStack Glance (image) service.
A valid Glance URL is required since it is a mandatory service.
Glance URL is retrieved from Keystone catalog unless disco-mode is set to 'manual' or a specific URL is provided with this option.

Example: C<--image-url="https://myopenstack.local:9292">

This URL can also be construct with options (--image-hostname, --image-proto, --image-port, --image-endpoint).

=item B<--image-hostname>

Set the hostname part of the Glance service URL.

=item B<--image-proto>

Set the protocol to use in the Glance service URL (default: 'https').

=item B<--image-port>

Set the port to use in the Glance service URL (default: 8774).

=item B<--image-endpoint>

Set the endpoint to use in the Glance service URL (default: '/v2').

=item B<--image-insecure>

Allow insecure TLS connection (default: '0').
When set to 0 the default insecure value passed with --insecure is used.

=item B<--image-timeout>

Set HTTP timeout in seconds (default: '0').
When set to 0 the default timeout value passed with --timeout is used.

=back

=head1 DESCRIPTION

B<custom>.

=cut
