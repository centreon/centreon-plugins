#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::meraki::cloudcontroller::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify' => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my (@disco_data, $disco_stats);
    $disco_stats->{start_time} = time();

    my $organizations = $options{custom}->get_organizations(disable_cache => 1);
    my $networks = $options{custom}->get_networks(
        organizations => [keys %{$self->{organizations}}],
        disable_cache => 1
    );
    my $devices = $options{custom}->get_devices(
        organizations => [keys %{$self->{organizations}}],
        disable_cache => 1
    );
    my $devices_statuses = $options{custom}->get_organization_device_statuses();

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};

    foreach (values %$devices) {
        my $node = {
            %$_,
            %{$devices_statuses->{$_->{serial}}},
            networkName => $networks->{ $devices_statuses->{$_->{serial}}->{networkId} }->{name},
            organizationName => $organizations->{ $networks->{ $devices_statuses->{$_->{serial}}->{networkId} }->{organizationId} }->{name},
            type => 'device'
        };

        push @disco_data, $node;
    }

    foreach (values %$networks) {
        my $node = {
            %$_,
            organizationName => $organizations->{ $_->{organizationId} }->{name},
            type => 'network'
        };

        push @disco_data, $node;
    }
   
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--prettify>

Prettify JSON output.

=item B<--ignore-permission-errors>

Continue the discovery and ignore permission errors (403 status code).

=back

=cut
