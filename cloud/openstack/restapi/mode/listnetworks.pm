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

package cloud::openstack::restapi::mode::listnetworks;

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
            "exclude:s" => { name => 'exclude' },
        });

    $self->{networks_infos} = ();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{status}}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping ${options{status}} instance."));
        return 1;
    }
    return 0;
}

sub listnetwork_request {
    my ($self, %options) = @_;

    my $urlpath = "/v2.0/networks";
    my $port = '9696';

    my $networkapi = $options{custom};
    my $webcontent = $networkapi->api_request(urlpath => $urlpath,
                                                port => $port,);

    foreach my $val (@{$webcontent->{networks}}) {
        next if ($self->check_exclude(status => $val->{status}));
        my $networkname = $val->{name};
        $self->{networks_infos}->{$networkname}->{id} = $val->{id};
        $self->{networks_infos}->{$networkname}->{tenant} = $val->{tenant_id};
        $self->{networks_infos}->{$networkname}->{state} = $val->{status};
        $self->{networks_infos}->{$networkname}->{admin_state} = $val->{admin_state_up};
    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'id', 'tenant', 'state', 'admin_state'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->listnetwork_request(%options);

    foreach my $networkname (keys %{$self->{networks_infos}}) {
        $self->{output}->add_disco_entry(name => $networkname,
                                         id => $self->{networks_infos}->{$networkname}->{id},
                                         tenant => $self->{networks_infos}->{$networkname}->{tenant},
                                         state => $self->{networks_infos}->{$networkname}->{state},
                                         admin_state => $self->{networks_infos}->{$networkname}->{admin_state},
                                        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->listnetwork_request(%options);

    foreach my $networkname (keys %{$self->{networks_infos}}) {
        $self->{output}->output_add(long_msg => sprintf("%s [id = %s, tenant = %s, state = %s, admin_state = %s]",
                                                        $networkname,
                                                        $self->{networks_infos}->{$networkname}->{id},
                                                        $self->{networks_infos}->{$networkname}->{tenant},
                                                        $self->{networks_infos}->{$networkname}->{state},
                                                        $self->{networks_infos}->{$networkname}->{admin_state}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List networks:');

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();

    exit 0;
}

1;

__END__

=head1 MODE

List OpenStack networks through Networking API V2.0

=over 8

=item B<--exlude>

Exclude specific instance's state (comma seperated list) (Example: --exclude=ERROR)

=back

=cut
