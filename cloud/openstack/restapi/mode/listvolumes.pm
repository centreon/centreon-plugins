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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "exclude:s"     => { name => 'exclude' },
            "tenant-id:s"   => { name => 'tenant_id' },
        });

    $self->{volumes_infos} = ();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{tenant_id}) || $self->{option_results}->{tenant_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --tenant-id option.");
        $self->{output}->option_exit();
    }
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{status}}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping ${options{status}} instance."));
        return 1;
    }
    return 0;
}

sub listvolume_request {
    my ($self, %options) = @_;

    my $urlpath = "/v2/".$self->{option_results}->{tenant_id}."/volumes/detail";
    my $port = '8776';

    my $volumeapi = $options{custom};
    my $webcontent = $volumeapi->api_request(urlpath => $urlpath,
                                                port => $port,);

    foreach my $val (@{$webcontent->{volumes}}) {
        next if ($self->check_exclude(status => $val->{status}));
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

    $self->listvolume_request(%options);

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

    $self->listvolume_request(%options);

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

=over 8

=item B<--tenant-id>

Set Tenant's ID

=item B<--exlude>

Exclude specific instance's state (comma seperated list) (Example: --exclude=error)

=back

=cut
