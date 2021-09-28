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

package network::versa::director::restapi::mode::listpaths;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-device-name:s' => { name => 'filter_device_name' },
        'filter-device-type:s' => { name => 'filter_device_type' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $orgs = $options{custom}->get_organizations();
    my $root_org_name = $options{custom}->find_root_organization_name(orgs => $orgs);
    my $devices = $options{custom}->get_devices(org_name => $root_org_name);

    my $results = {};
    foreach my $device (values %{$devices->{entries}}) {
        if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
            $device->{name} !~ /$self->{option_results}->{filter_device_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_device_type}) && $self->{option_results}->{filter_device_type} ne '' &&
            $device->{type} !~ /$self->{option_results}->{filter_device_type}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter type.", debug => 1);
            next;
        }

        my $paths = $options{custom}->get_device_paths(
            org_name => $root_org_name,
            device_name => $device->{name}
        );
        my $i = 0;
        foreach (@{$paths->{entries}}) {
            $results->{ $device->{name} . ':' . $i } = {
                device_name => $device->{name},
                device_type => $device->{type},
                remote_site_name => $_->{remoteSiteName},
                local_wan_link => $_->{localWanLink},
                remote_wan_link => $_->{remoteWanLink}
            };
            $i++;
        }
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach (values %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[device_name: %s][device_type: %s][remote_site_name: %s][local_wan_link: %s][remote_wan_link: %s]',
                $_->{device_name},
                $_->{device_type},
                $_->{remote_site_name},
                $_->{local_wan_link},
                $_->{remote_wan_link}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List device paths:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['device_name', 'device_type', 'remote_site_name', 'local_wan_link', 'remote_wan_link']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (values %$results) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List paths by devices.

=over 8

=item B<--filter-device-name>

Filter device by name (Can be a regexp).

=item B<--filter-device-type>

Filter device by type (Can be a regexp).

=back

=cut
    
