#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::mode::listvolumes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "data:s"                => { name => 'data' },
            "hostname:s"            => { name => 'hostname' },
            "http-peer-addr:s"      => { name => 'http_peer_addr' },
            "port:s"                => { name => 'port', default => '5000' },
            "proto:s"               => { name => 'proto' },
            "urlpath:s"             => { name => 'url_path', default => '/v3/auth/tokens' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "proxypac:s"            => { name => 'proxypac' },
            "credentials"           => { name => 'credentials' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "ssl:s"                 => { name => 'ssl', },
            "header:s@"             => { name => 'header' },
            "exclude:s"             => { name => 'exclude' },
            "timeout:s"             => { name => 'timeout' },
            "tenant-id:s"           => { name => 'tenant_id' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    $self->{volumes_infos} = ();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{http}->set_options(%{$self->{option_results}})
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{status}}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping ${options{status}} instance."));
        return 1;
    }
    return 0;
}

sub token_request {
    my ($self, %options) = @_;

    $self->{method} = 'GET';
    if (defined($self->{option_results}->{data})) {
        local $/ = undef;
        if (!open(FILE, "<", $self->{option_results}->{data})) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Could not read file '%s': %s", $self->{option_results}->{data}, $!));
            $self->{output}->display();
            $self->{output}->exit();
        }
        $self->{json_request} = <FILE>;
        close FILE;
        $self->{method} = 'POST';
    }

    my $response = $self->{http}->request(method => $self->{method}, query_form_post => $self->{json_request});
    my $headers = $self->{http}->get_header();
    eval {
        $self->{header} = $headers->header('X-Subject-Token');
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot retrieve API Token");
        $self->{output}->option_exit();
    }
}

sub api_request {
    my ($self, %options) = @_;

    $self->{method} = 'GET';
    $self->{option_results}->{url_path} = "/v2/".$self->{option_results}->{tenant_id}."/volumes/detail";
    $self->{option_results}->{port} = '8776';
    @{$self->{option_results}->{header}} = ('X-Auth-Token:' . $self->{header}, 'Accept:application/json');
    $self->{http}->set_options(%{$self->{option_results}});

    my $webcontent;
    my $jsoncontent = $self->{http}->request(method => $self->{method});

    my $json = JSON->new;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    foreach my $val (@{$webcontent->{volumes}}) {
        my $volumename = $val->{name};
        $self->{volumes_infos}->{$volumename}->{id} = $val->{id};
        $self->{volumes_infos}->{$volumename}->{zone} = $val->{availability_zone};
        $self->{volumes_infos}->{$volumename}->{size} = $val->{size};
        $self->{volumes_infos}->{$volumename}->{type} = $val->{volume_type};
        $self->{volumes_infos}->{$volumename}->{state} = $val->{status};
    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'id', 'zone', 'type', 'size', 'state'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->token_request();
    $self->api_request();

    foreach my $volumename (keys %{$self->{volumes_infos}}) {
        $self->{output}->add_disco_entry(name => $volumename,
                                         id => $self->{volumes_infos}->{$volumename}->{id},
                                         zone => $self->{volumes_infos}->{$volumename}->{zone},
                                         size => $self->{volumes_infos}->{$volumename}->{size}."Gb",
                                         type => $self->{volumes_infos}->{$volumename}->{type},
                                         state => $self->{volumes_infos}->{$volumename}->{state},
                                        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->token_request();
    $self->api_request();

    foreach my $volumename (keys %{$self->{volumes_infos}}) {
        $self->{output}->output_add(long_msg => sprintf("%s [id = %s, zone = %s, size = %sGb, type = %s, state = %s]",
                                                        $volumename,
                                                        $self->{volumes_infos}->{$volumename}->{id},
                                                        $self->{volumes_infos}->{$volumename}->{zone},
                                                        $self->{volumes_infos}->{$volumename}->{size},
                                                        $self->{volumes_infos}->{$volumename}->{type},
                                                        $self->{volumes_infos}->{$volumename}->{state}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List volumes:');

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();

    exit 0;
}

1;

__END__

=head1 MODE

List OpenStack volumes through Block Storage API V2

JSON OPTIONS:

=over 8

=item B<--data>

Set file with JSON request

=back

HTTP OPTIONS:

=over 8

=item B<--hostname>

IP Addr/FQDN of OpenStack Compute's API

=item B<--http-peer-addr>

Set the address you want to connect (Useful if hostname is only a vhost. no ip resolve)

=item B<--port>

Port used by OpenStack Keystone's API (Default: '5000')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get API's Token (Default: '/v3/auth/tokens')

=item B<--proxyurl>

Proxy URL

=item B<--proxypac>

Proxy pac file (can be an url or local file)

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username

=item B<--password>

Specify password

=item B<--ssl>

Specify SSL version (example : 'sslv3', 'tlsv1'...)

=item B<--header>

Set HTTP headers (Multiple option. Example: --header='Content-Type: xxxxx')

=item B<--exlude>

Exclude specific instance's state (comma seperated list) (Example: --exclude=Paused,Running,Off,Exited)

=item B<--timeout>

Threshold for HTTP timeout (Default: 3)

=back

OPENSTACK OPTIONS:

=over 8

=item B<--tenant-id>

Set Tenant's ID

=back

=cut
