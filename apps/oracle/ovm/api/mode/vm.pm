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

package apps::oracle::ovm::api::mode::vm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'running state: %s',
         $self->{result_values}->{running_state}
    );
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    
    return "Virtual machine '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Virtual machines ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vm-running', nlabel => 'virtualmachines.running.count', display_ok => 0, set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'vm-stopped', nlabel => 'virtualmachines.stopped.count', display_ok => 0, set => {
                key_values => [ { name => 'stopped' }, { name => 'total' } ],
                output_template => 'stopped: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vm} = [
        { label => 'status', threshold => 2, set => {
                key_values => [
                    { name => 'running_state' }, { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $manager = $options{custom}->request_api(endpoint => '/Manager');
    if ($manager->[0]->{managerRunState} ne 'RUNNING') {
        $self->{output}->add_option_msg(short_msg => 'manager is not running.');
        $self->{output}->option_exit();
    }

    my $vms = $options{custom}->request_api(endpoint => '/Vm');

    $self->{global} = { running => 0, stopped => 0, total => 0 };
    $self->{vm} = {};
    foreach (@$vms) {
        my $name = $_->{id}->{value};
        $name = $_->{name}
            if (defined($_->{name}) && $_->{name} ne '');

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping virtual machine '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vm}->{$name} = {
            name => $name,
            running_state => lc($_->{vmRunState})
        };
        $self->{global}->{ lc($_->{vmRunState}) }++
            if (defined($self->{global}->{ lc($_->{vmRunState}) }));
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check virtual machines.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter virtual machines by name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{running_status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{running_status}, %{name}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{running_status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'vm-running', 'vm-stopped'.

=back

=cut
