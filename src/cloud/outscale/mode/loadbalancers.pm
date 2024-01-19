#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package cloud::outscale::mode::loadbalancers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub lb_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking load balancer '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_lb_output {
    my ($self, %options) = @_;

    return sprintf(
        "load balancer '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of load balancers ';
}

sub prefix_vm_metrics_output {
    my ($self, %options) = @_;

    return 'number of virtual machines ';
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "virtual machine '" . $options{instance_value}->{vmName} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'lbs', type => 3, cb_prefix_output => 'prefix_lb_output', cb_long_output => 'lb_long_output', indent_long_output => '    ', message_multiple => 'All load balancers are ok',
            group => [
                { name => 'vm_metrics', type => 0, cb_prefix_output => 'prefix_vm_metrics_output' },
                { name => 'vms', display_long => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'all virtual machines are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'load-balancers-detected', display_ok => 0, nlabel => 'load_balancers.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vm_metrics} = [
        { label => 'load-balancer-vms-up', nlabel => 'load_balancer.virtual_machines.up.count', set => {
                key_values => [ { name => 'up' } ],
                output_template => 'up: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'load-balancer-vms-down', nlabel => 'load_balancer.virtual_machines.down.count', set => {
                key_values => [ { name => 'down' } ],
                output_template => 'down: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vms} = [
        {
            label => 'vm-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'vmName' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' },
        'vm-tag-name:s' => { name => 'vm_tag_name', default => 'name' }
    });

    return $self;
}

sub get_vm_name {
    my ($self, %options) = @_;

    foreach my $vm (@{$options{vms}}) {
        next if ($vm->{VmId} ne $options{vm_id});

        foreach my $tag (@{$vm->{Tags}}) {
            return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{vm_tag_name}$/i);
        }
    }

    return $options{vm_id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $lbs = $options{custom}->load_balancer_read();
    my $vms = $options{custom}->read_vms();

    $self->{global} = { detected => 0 };
    $self->{lbs} = {};

    foreach my $lb (@$lbs) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $lb->{LoadBalancerName} !~ /$self->{option_results}->{filter_name}/);

        $self->{global}->{detected}++;

        $self->{lbs}->{ $lb->{LoadBalancerName} } = {
            name => $lb->{LoadBalancerName},
            vm_metrics => { up => 0, down => 0 },
            vms => {}
        };

        my $members = $options{custom}->read_vms_health(load_balancer_name => $lb->{LoadBalancerName});
        foreach (@$members) {
            my $name = $self->get_vm_name(vms => $vms, vm_id => $_->{VmId});

            $self->{lbs}->{ $lb->{LoadBalancerName} }->{vms}->{ $_->{VmId} } = {
                vmName => $name,
                state => lc($_->{State})
            };
            $self->{lbs}->{ $lb->{LoadBalancerName} }->{vm_metrics}->{ lc($_->{State}) }++
                if (defined($self->{lbs}->{ $lb->{LoadBalancerName} }->{vm_metrics}->{ lc($_->{State}) }));
        }
    }
}

1;

__END__

=head1 MODE

Check load balancers.

=over 8

=item B<--filter-name>

Filter load balancers by name.

=item B<--vm-tag-name>

Virtual machine tags to used for the name (default: 'name').

=item B<--unknown-vm-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{vmName}

=item B<--warning-vm-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{vmName}

=item B<--critical-vm-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{vmName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'load-balancers-detected', 'load-balancer-vms-up', ''load-balancer-vms-down'.

=back

=cut
