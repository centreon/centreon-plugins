#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::mode::listvms;

use strict;
use warnings;
use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_vms();
    my $entities = $result->{entities} // [];

    for my $vm (@{$entities}) {
        my $name        = $vm->{name}        // $vm->{uuid} // 'unknown';
        my $uuid        = $vm->{uuid}        // 'N/A';
        my $power_state = $vm->{power_state} // 'unknown';
        my $host_uuid   = $vm->{host_uuid}   // 'N/A';

        $self->{output}->output_add(
            long_msg => sprintf(
                "  name: %-40s uuid: %-40s power_state: %-8s host: %s",
                $name, $uuid, $power_state, $host_uuid
            )
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List of Nutanix VMs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    $self->{output}->add_disco_format(elements => ['name', 'uuid', 'power_state', 'host_uuid', 'num_vcpus', 'memory_mb']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_vms();
    my $entities = $result->{entities} // [];

    for my $vm (@{$entities}) {
        $self->{output}->add_disco_entry(
            name        => $vm->{name}        // 'unknown',
            uuid        => $vm->{uuid}        // 'N/A',
            power_state => $vm->{power_state} // 'unknown',
            host_uuid   => $vm->{host_uuid}   // 'N/A',
            num_vcpus   => $vm->{num_vcpus}   // 0,
            memory_mb   => int(($vm->{memory_mb} // 0)),
        );
    }
}

1;

__END__

=head1 MODE

List Nutanix VMs for service discovery.

=over 8

=back

=cut
