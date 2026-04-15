#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::linux::libvirt::local::mode::vmstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf("state is '%s'", $self->{result_values}->{state});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vms', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_vm_output',
          message_multiple => 'All VMs status are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{vms} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{state} !~ /^running$/', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'vm-name:s'      => { name => 'vm_name',      default => '' },
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => '--vm-name cannot be used together with --include-name or --exclude-name.')
        if $self->{option_results}->{vm_name} ne '' && ($self->{option_results}->{include_name} ne '' || $self->{option_results}->{exclude_name} ne '');
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vms} = {};
    if ($self->{option_results}->{vm_name} ne '') {
        # virsh domstate <vm>
        # running
        my $stdout = $options{custom}->execute_command(virsh_args => 'domstate ' . $self->{option_results}->{vm_name});
        my ($state) = ($stdout =~ /^\s*(.+?)\s*$/m);
        $state =~ s/\s+/_/g;

        $state = lc($state // 'unknown');
        $self->{vms}->{$self->{option_results}->{vm_name}} = {
            display => $self->{option_results}->{vm_name},
            state   => $state
        };
    } else {
        # virsh list --all output:
        #  Id   Name            State
        # -----------------------------------
        #  1    myvm            running
        #  -    stopped-vm      shut off
        my $stdout = $options{custom}->execute_command(virsh_args => 'list --all');

        foreach (split(/\n/, $stdout)) {
            next if /^\s*(Id\s+Name)\s*/i;
            next unless /^\s*(\S+)\s+(\S+)\s+(.+?)\s*$/;

            my ($id, $name, $state) = ($1, $2, $3);

            next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name});

            # normalise state: 'shut off' → 'shut_off'
            $state = lc($state);
            $state =~ s/\s+/_/g;

            $self->{vms}->{$name} = {
                display => $name,
                state   => $state
            };
        }
    }

    $self->{output}->option_exit(short_msg => 'No VM found.')
        unless %{$self->{vms}};
}

1;

__END__

=head1 MODE

Check virtual machines status (C<virsh list --all>).

=over 8

=item B<--vm-name>

Check only this specific VM (skips list discovery).
Cannot be used together with --include-name or --exclude-name.

=item B<--include-name>

Filter VMs by name (regexp).

=item B<--exclude-name>

Exclude VMs whose name matches this regexp.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
Can use: %{state}, %{display}.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: "%{state} !~ /^running$/").

=back

=cut
