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

package network::versa::director::restapi::mode::cache;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-org-name:s'    => { name => 'filter_org_name' },
        'filter-device-name:s' => { name => 'filter_device_name' },
        'paths-by-orgs'        => { name => 'paths_by_orgs' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $orgs = $options{custom}->cache_organizations();
    my $root_org_name = $options{custom}->find_root_organization_name(orgs => $orgs);
    foreach my $org (values %{$orgs->{entries}}) {
        if (defined($self->{option_results}->{filter_org_name}) && $self->{option_results}->{filter_org_name} ne '' &&
            $org->{name} !~ /$self->{option_results}->{filter_org_name}/) {
            $self->{output}->output_add(long_msg => "skipping org '" . $org->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        my $devices = $options{custom}->cache_devices(org_name => $org->{name});
        foreach my $device (values %{$devices->{entries}}) {
            if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
                $device->{name} !~ /$self->{option_results}->{filter_device_name}/) {
                $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter name.", debug => 1);
                next;
            }

            next if (!defined($self->{option_results}->{paths_by_orgs}) && $org->{name} ne $root_org_name);

            # we check all paths from the root org
            $options{custom}->cache_device_paths(
                org_name => $org->{name},
                device_name => $device->{name}
            );
        }
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'Cache files created successfully'
    );
}

1;

__END__

=head1 MODE

Create cache files (other modes could use it with --cache-use option).

=over 8

=item B<--filter-org-name>

Filter organizations by name (Can be a regexp).

=item B<--filter-device-name>

Filter devices by name (Can be a regexp).

=item B<--paths-by-orgs>

Create paths cache files by organizations.

=back

=cut
