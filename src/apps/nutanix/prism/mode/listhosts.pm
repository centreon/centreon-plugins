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

package apps::nutanix::prism::mode::listhosts;

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

    my $result   = $options{custom}->get_hosts();
    my $entities = $result->{entities} // [];

    for my $host (@{$entities}) {
        my $name  = $host->{name}  // $host->{uuid} // 'unknown';
        my $uuid  = $host->{uuid}  // 'N/A';
        my $ip    = $host->{hypervisor_address} // 'N/A';
        my $model = $host->{block_model_name}   // 'N/A';

        $self->{output}->output_add(
            long_msg => sprintf(
                "  name: %-30s uuid: %-40s ip: %-16s model: %s",
                $name, $uuid, $ip, $model
            )
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List of Nutanix hosts:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

# Appelé par le framework Centreon pour la découverte automatique
sub disco_format {
    my ($self, %options) = @_;
    $self->{output}->add_disco_format(elements => ['name', 'uuid', 'ip', 'model', 'num_vms']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_hosts();
    my $entities = $result->{entities} // [];

    for my $host (@{$entities}) {
        $self->{output}->add_disco_entry(
            name    => $host->{name}                // 'unknown',
            uuid    => $host->{uuid}                // 'N/A',
            ip      => $host->{hypervisor_address}  // 'N/A',
            model   => $host->{block_model_name}    // 'N/A',
            num_vms => $host->{num_vms}             // 0,
        );
    }
}

1;

__END__

=head1 MODE

List Nutanix hosts for service discovery.

=over 8

=back

=cut
