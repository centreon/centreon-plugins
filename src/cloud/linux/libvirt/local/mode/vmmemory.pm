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

package cloud::linux::libvirt::local::mode::vmmemory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($used_value, $used_unit)   = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_bytes});
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_bytes});

    return sprintf(
        'memory used: %s %s / %s %s (%.2f %%)',
        $used_value, $used_unit, $total_value, $total_unit,
        $self->{result_values}->{usage_prct}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vms', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_vm_output',
          message_multiple => 'All VMs memory usage are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{vms} = [
        { label => 'memory-usage', nlabel => 'vm.memory.usage.bytes', set => {
                key_values => [ { name => 'used_bytes' }, { name => 'total_bytes' },
                                { name => 'usage_prct' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_bytes', template => '%s',
                      unit => 'B', min => 0, max => 'total_bytes', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', nlabel => 'vm.memory.usage.percentage', set => {
                key_values => [ { name => 'usage_prct' }, { name => 'display' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { value => 'usage_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-rss', nlabel => 'vm.memory.rss.bytes', set => {
                key_values => [ { name => 'rss_bytes' }, { name => 'display' } ],
                output_template => 'RSS: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'rss_bytes', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1 }
                ]
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

    my @running_vms;
    if ($self->{option_results}->{vm_name} ne '') {
        push @running_vms, $self->{option_results}->{vm_name};
    } else {
        my $stdout_list = $options{custom}->execute_command(virsh_args => 'list --state-running');
        foreach (split(/\n/, $stdout_list)) {
            next if /^\s*(Id\s+Name)\s*/i; # header
            next unless /^\s*\d+\s+(\S+)\s+running/;
            my $name = $1;
            next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name});
            push @running_vms, $name;
        }
        $self->{output}->option_exit(short_msg => 'No running VM found.')
            unless @running_vms;
    }

    $self->{vms} = {};

    foreach my $name (@running_vms) {
        # virsh dommemstat <domain>
        # actual    1048576   (current balloon value, KiB)
        # available 1048576   (total memory available in guest, KiB)
        # unused    524288    (unused memory in guest, KiB)
        # rss       1048576   (resident set size on host, KiB)
        my $stdout = $options{custom}->execute_command(virsh_args => "dommemstat $name");

        my %mem;
        foreach (split(/\n/, $stdout)) {
            $mem{$1} = $2 if /^\s*(\w+)\s+(\d+)/;
        }

        # fallback: use 'actual' if 'available' is absent (balloon driver not active)
        my $total_kib  = $mem{available} // $mem{actual} // 0;
        my $unused_kib = $mem{unused}    // 0;
        my $rss_kib    = $mem{rss}       // 0;

        next unless $total_kib;

        my $used_kib = $total_kib - $unused_kib;

        $self->{vms}->{$name} = {
            display     => $name,
            used_bytes  => $used_kib  * 1024,
            total_bytes => $total_kib * 1024,
            usage_prct  => $used_kib / $total_kib * 100,
            rss_bytes   => $rss_kib   * 1024
        };
    }
}

1;

__END__

=head1 MODE

Check virtual machines memory usage (C<virsh dommemstat>).

Requires the balloon driver to be enabled inside the guest OS for accurate
available/unused values. Without it, only 'actual' (balloon size) is reported.

=over 8

=item B<--vm-name>

Check only this specific VM.
Cannot be used together with --include-name or --exclude-name.

=item B<--include-name>

Filter VMs by name (regexp).

=item B<--exclude-name>

Exclude VMs whose name matches this regexp.

=item B<--warning-memory-usage>

Warning threshold for memory used (bytes).

=item B<--critical-memory-usage>

Critical threshold for memory used (bytes).

=item B<--warning-memory-usage-prct>

Warning threshold for memory usage (%).

=item B<--critical-memory-usage-prct>

Critical threshold for memory usage (%).

=item B<--warning-memory-rss>

Warning threshold for RSS memory on host (bytes).

=item B<--critical-memory-rss>

Critical threshold for RSS memory on host (bytes).

=back

=cut
