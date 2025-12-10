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

package cloud::openstack::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::misc qw/json_encode/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'        => { name => 'prettify', default => 0 },
        'horizon-url:s'   => { name => 'horizon_url' , default => '' },
        'refresh-catalog' => { name => 'refresh_catalog' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->{$_} = $self->{option_results}->{$_} foreach qw/horizon_url prettify refresh_catalog/;
}

sub manage_selection {
    my ($self, %options) = @_;

    # In discover mode we don't use the Keystone cache because we want to refresh the service list
    my ($services)  = $options{custom}->keystone_authent( dont_read_cache => 1, discover_mode => 1 );

    return { managed_services => [],
                       others_services => [],
                       keystone_url => '',
                       horizon_url => '',
           } unless @{$services->{services}};

    my %discovered_services;

    my @horizon_url;
    push @horizon_url, $self->{horizon_url} if $self->{horizon_url} ne '';

    foreach (@{$services->{services}}) {
        $discovered_services{$_->{type}.'##'.$_->{name}} = { type => $_->{type}, name => $_->{name} };

        # Trying to guess the Horizon URL from the Keystone/Identity endpoints
        if ($_->{type} eq 'identity' && !@horizon_url) {
            my %test;
            foreach my $endpoint (@{$_->{endpoints}}) {
                my $horizon_url = $endpoint->{url} =~ s/^(https?:\/\/[-\.\w]+).*$/$1/r;
                next if $test{$horizon_url};
                $test{$horizon_url} = 1;
                my $result = $options{custom}->ping_service(type => 'dashboard',
                                                            service_url => $horizon_url,
                                                            expected_data => 'auto',
                                                            endpoint_suffix => 'auto',
                                                            token => '');
                push @horizon_url, $horizon_url
                    if $result->{http_status} == 200 && $result->{valid_content};
            }
        }
    }

    # This filter represents services for which a service will be automatically created in Centreon
    # Other services will be listed but for us a "list-services" call from the user will be necessary later
    my $filter = qr/(?:identity|image|network|compute|placement|volumev3)/;
    @horizon_url = ( 'http://please_change_me' ) unless @horizon_url;
    my %disco_data = ( managed_services => [ grep { $_->{type} =~ $filter } values %discovered_services ],
                       others_services  => [ grep { $_->{type} !~ $filter } values %discovered_services ],
                       keystone_url     => $options{custom}->{identity_base_url},
                       horizon_url      => join ',', @horizon_url
                     );

    return \%disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = $self->manage_selection(%options);

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @{$results->{managed_services}} ? 1 : 0;
    $disco_stats->{results} = $results;

    my $encoded_data = json_encode($disco_stats, prettify => $self->{prettify},
                                                 output => $self->{output},
                                                 no_exit => 1);

    if ($self->{refresh_catalog}) {
        if ($encoded_data) {
            $self->{output}->output_add(short_msg => 'Keystone service catalog cache refreshed successfully.');
        } else {
            $self->{output}->output_add(severity => 'UNKNOWN', short_msg => 'Cannot refresh Keystone service catalog cache.' );
        }
        $self->{output}->display();
    } else {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}'
            unless $encoded_data;
        $self->{output}->output_add(short_msg => $encoded_data);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    }
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

OpenStack Services discovery

=over 8

=item B<--prettify>

Prettify JSON output.

=item B<--refresh-catalog>

Only refresh the Keystone service catalog cache.

=item B<--horizon-url>

Set the URL to use for the C<Horizon> service.
If this option is not set an attempt will be made to discover the C<Horizon> service on port 443 of the C<Keystone> service IP.
If the C<Horizon> service cannot be discovered the default URL C<http://please_change>_me will be used for the C<Horizon> service.

=back

=cut
