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

package apps::nutanix::prism::mode::vmscount;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    # type => 0 : compteur global (pas d'instance multiple)
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'total',
            nlabel => 'vms.total.count',
            set    => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total VMs: %d',
                perfdatas       => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label  => 'on',
            nlabel => 'vms.on.count',
            set    => {
                key_values      => [ { name => 'on' } ],
                output_template => 'powered on: %d',
                perfdatas       => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label  => 'off',
            nlabel => 'vms.off.count',
            set    => {
                key_values      => [ { name => 'off' } ],
                output_template => 'powered off: %d',
                perfdatas       => [
                    { template => '%d', min => 0 }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_vms();
    my $entities = $result->{entities} // [];

    my $total = scalar(@{$entities});
    my $on    = scalar(grep { ($_->{power_state} // '') eq 'on' } @{$entities});
    my $off   = $total - $on;

    $self->{global} = {
        total => $total,
        on    => $on,
        off   => $off,
    };
}

1;

__END__

=head1 MODE

Count Nutanix VMs by power state through Prism REST API.

=over 8

=item B<--warning-total>

Warning threshold for total VM count.

=item B<--critical-total>

Critical threshold for total VM count.

=item B<--warning-on>

Warning threshold for powered-on VM count.

=item B<--critical-on>

Critical threshold for powered-on VM count.

=item B<--warning-off>

Warning threshold for powered-off VM count.

=item B<--critical-off>

Critical threshold for powered-off VM count.

=back

=cut
