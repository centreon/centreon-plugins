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

package network::versa::director::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'resource-type:s' => { name => 'resource_type' },
        'prettify'        => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'device';
    }
    if ($self->{option_results}->{resource_type} !~ /^device|organization$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub discovery_devices {
    my ($self, %options) = @_;

    my $disco_data = [];
    foreach my $device (values %{$options{devices}->{entries}}) {
        my $node = {};
        $node->{uuid} = $device->{uuid};
        $node->{name} = $device->{name};
        $node->{type} = $device->{type};
        $node->{ip} = $device->{'ip-address'};
        $node->{organizations} = [];
        foreach (@{$device->{orgs}}) {
            push @{$node->{organizations}}, $options{organizations}->{entries}->{ $_->{uuid} }->{name};
        }

        push @$disco_data, $node;
    }

    return $disco_data;
}

sub discovery_organizations {
    my ($self, %options) = @_;

    my $disco_data = [];
    foreach my $org (values %{$options{organizations}->{entries}}) {
        my $node = {};
        $node->{uuid} = $org->{uuid};
        $node->{name} = $org->{name};
        $node->{devices} = [];
        foreach (@{$org->{appliances}}) {
            push @{$node->{devices}}, $options{devices}->{entries}->{ $_ }->{name};
        }

        push @$disco_data, $node;
    }

    return $disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $organizations = $options{custom}->get_organizations(disable_cache => 1);
    my $devices = $options{custom}->get_appliances(disable_cache => 1);

    my $results = [];
    if ($self->{option_results}->{resource_type} eq 'device') {
        $results = $self->discovery_devices(
            devices => $devices,
            organizations => $organizations
        );
    } else {
        $results = $self->discovery_organizations(
            devices => $devices,
            organizations => $organizations
        );
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$results);
    $disco_stats->{results} = $results;

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

=item B<--resource-type>

Choose the type of resources to discover (Can be: 'device', 'organization').

=back

=cut
