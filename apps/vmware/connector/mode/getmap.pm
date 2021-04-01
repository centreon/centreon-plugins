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

package apps::vmware::connector::mode::getmap;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'esx-hostname:s'     => { name => 'esx_hostname' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'scope-cluster:s'    => { name => 'scope_cluster' },
        'vm-no'              => { name => 'vm_no' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'getmap');
    
    foreach my $host_id (sort { $response->{data}->{$a}->{name} cmp $response->{data}->{$b}->{name} } keys %{$response->{data}}) {
        $self->{output}->output_add(long_msg => sprintf("  %s [v%s] %s", $response->{data}->{$host_id}->{name}, 
            $response->{data}->{$host_id}->{version}, 
            defined($self->{option_results}->{vm_no}) ? '' : ':'));

        foreach my $vm_id (sort { $response->{data}->{$host_id}->{vm}->{$a}->{name} cmp $response->{data}->{$host_id}->{vm}->{$b}->{name} } keys %{$response->{data}->{$host_id}->{vm}}) {
            $self->{output}->output_add(long_msg => sprintf("      %s [%s]", 
                                                            $response->{data}->{$host_id}->{vm}->{$vm_id}->{name}, $response->{data}->{$host_id}->{vm}->{$vm_id}->{power_state}));
        }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List ESX host(s):');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

List ESX hosts and Virtual machines.

=over 8

=item B<--esx-hostname>

ESX hostname to list.
If not set, we list all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--vm-no>

Don't list virtual machines.

=back

=cut
