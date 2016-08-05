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

package cloud::openstack::restapi::mode::listhypervisors;

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

    $self->{hypervisor_infos} = ();
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

sub listhypervisor_request {
    my ($self, %options) = @_;

    my $urlpath = "/v2/".$self->{option_results}->{tenant_id}."/os-hypervisors/detail";
    my $port = '8774';

    my $hypervisorapi = $options{custom};
    my $webcontent = $hypervisorapi->api_request(urlpath => $urlpath,
                                                port => $port,);

    foreach my $val (@{$webcontent->{hypervisors}}) {
        next if ($self->check_exclude(status => $val->{state}));
        my $hypervisorname = $val->{hypervisor_hostname};
        $self->{hypervisor_infos}->{$hypervisorname}->{id} = $val->{id};
        $self->{hypervisor_infos}->{$hypervisorname}->{ipaddress} = $val->{host_ip};
        $self->{hypervisor_infos}->{$hypervisorname}->{type} = $val->{hypervisor_type};
        $self->{hypervisor_infos}->{$hypervisorname}->{status} = $val->{status};
        $self->{hypervisor_infos}->{$hypervisorname}->{state} = $val->{state};
    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'ip', 'type', 'status', 'state'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->listhypervisor_request(%options);

    foreach my $hypervisorname (keys %{$self->{hypervisor_infos}}) {
        $self->{output}->add_disco_entry(name => $hypervisorname,
                                         id => $self->{hypervisor_infos}->{$hypervisorname}->{id},
                                         ip => $self->{hypervisor_infos}->{$hypervisorname}->{ipaddress},
                                         type => $self->{hypervisor_infos}->{$hypervisorname}->{type},
                                         status => $self->{hypervisor_infos}->{$hypervisorname}->{status},
                                         state => $self->{hypervisor_infos}->{$hypervisorname}->{state},
                                        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->listhypervisor_request(%options);

    foreach my $hypervisorname (keys %{$self->{hypervisor_infos}}) {
        $self->{output}->output_add(long_msg => sprintf("%s [id = %s, ip = %s, type = %s, status = %s, state = %s]",
                                                        $hypervisorname,
                                                        $self->{hypervisor_infos}->{$hypervisorname}->{id},
                                                        $self->{hypervisor_infos}->{$hypervisorname}->{ipaddress},
                                                        $self->{hypervisor_infos}->{$hypervisorname}->{type},
                                                        $self->{hypervisor_infos}->{$hypervisorname}->{status},
                                                        $self->{hypervisor_infos}->{$hypervisorname}->{state},));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List hypervisors:');

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();

    exit 0;
}

1;

__END__

=head1 MODE

List OpenStack hypervisors through Compute API V2

=head2 OPENSTACK OPTIONS

=item B<--tenant-id>

Set Tenant's ID

=head2 MODE OPTIONS

=item B<--exlude>

Exclude specific instance's state (comma seperated list) (Example: --exclude=down)

=back

=cut
