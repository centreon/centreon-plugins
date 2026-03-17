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

package cloud::linux::libvirt::local::mode::poolstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);

my @_pool_keys = qw(name state autostart);

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf("state is '%s' [autostart: %s]",
        $self->{result_values}->{state},
        $self->{result_values}->{autostart}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($used_value, $used_unit)   = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_bytes});
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_bytes});

    return sprintf(
        'space used: %s %s / %s %s (%.2f %%)',
        $used_value, $used_unit, $total_value, $total_unit,
        $self->{result_values}->{usage_prct}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pools', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_pool_output',
          message_multiple => 'All storage pools are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{pools} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{state} !~ /^running$/', set => {
                key_values => [ { name => 'state' }, { name => 'autostart' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'space-usage', nlabel => 'pool.space.usage.bytes', set => {
                key_values => [ { name => 'used_bytes' }, { name => 'total_bytes' },
                                { name => 'usage_prct' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_bytes', template => '%s',
                      unit => 'B', min => 0, max => 'total_bytes', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'pool.space.usage.percentage', set => {
                key_values => [ { name => 'usage_prct' }, { name => 'name' } ],
                output_template => 'space used: %.2f %%',
                perfdatas => [
                    { value => 'usage_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-free', nlabel => 'pool.space.free.bytes', set => {
                key_values => [ { name => 'free_bytes' }, { name => 'name' } ],
                output_template => 'space free: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'free_bytes', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return "Pool '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'pool-name:s'    => { name => 'pool_name',    default => '' },
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => '--pool-name cannot be used together with --include-name or --exclude-name.')
        if $self->{option_results}->{pool_name} ne '' && ($self->{option_results}->{include_name} ne '' || $self->{option_results}->{exclude_name} ne '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my @pool_names;
    if ($self->{option_results}->{pool_name} ne '') {
        push @pool_names, $self->{option_results}->{pool_name};
    } else {
        # virsh pool-list --all
        #  Name      State    Autostart
        # --------------------------------
        #  default   active   yes
        #  pool1     inactive no
        my $stdout_list = $options{custom}->execute_command(virsh_args => 'pool-list --all');
        foreach (split(/\n/, $stdout_list)) {
            next if /^\s*(Name\s+State)\s*/i; # header
            next unless /^\s*(\S+)\s+(active|inactive)\s+(yes|no)\s*$/i;
            push @pool_names, $1;
        }
    }

    $self->{pools} = {};

    foreach my $name (@pool_names) {
        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name});

        # virsh pool-info --bytes <pool>
        # Name:           default
        # State:          running
        # Autostart:      yes
        # Capacity:       999511535616
        # Allocation:     134679994368
        # Available:      864831541248
        my $info = $options{custom}->execute_command(virsh_args => "pool-info --bytes $name");

        my %pool_data;
        foreach (split(/\n/, $info)) {
            $pool_data{lc($1)} = $2 if /^\s*([^:]+):\s+(.+?)$/;
        }

        my $capacity = $pool_data{capacity} // 0;
        my $alloc = $pool_data{allocation} // 0;

        $self->{pools}->{$name} = {
            name        => $name // '-',
            state       => lc($pool_data{state} // 'unknown') =~ s/\s+/_/gr, # Normalize state (e.g., "shut off" -> "shut_off")
            autostart   => lc($pool_data{autostart} // 'unknown'),
            total_bytes => $capacity, 
            used_bytes  => $alloc,
            free_bytes  => $pool_data{available} // 0,
            usage_prct  => $capacity > 0 ? $alloc / $capacity * 100 : 0
        };
    }

    $self->{output}->option_exit(short_msg => 'No matching storage pool found.')
        unless keys %{$self->{pools}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_pool_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item (sort { $a->{name} cmp $b->{name} } values %{$self->{pools}}) {
        $self->{output}->add_disco_entry(map { $_ => $item->{$_} } @_pool_keys);
    }
}

1;

__END__

=head1 MODE

Check C<libvirt> storage pools status and usage (C<virsh pool-list> / C<virsh pool-info>).

=over 8

=item B<--pool-name>

Check only this specific pool.

=item B<--include-name>

Filter pools by name (regexp).

=item B<--exclude-name>

Exclude pools whose name matches this regexp.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '').
Can use: %{state}, %{autostart}, %{name}.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: "%{state} !~ /^running$/").

=item B<--warning-space-usage>

Warning threshold for space used (bytes).

=item B<--critical-space-usage>

Critical threshold for space used (bytes).

=item B<--warning-space-usage-prct>

Warning threshold for space usage (%).

=item B<--critical-space-usage-prct>

Critical threshold for space usage (%).

=item B<--warning-space-free>

Warning threshold for free space (bytes).

=item B<--critical-space-free>

Critical threshold for free space (bytes).

=back

=cut
