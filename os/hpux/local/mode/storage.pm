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

package os::hpux::local::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    if ($options{new_datas}->{$self->{instance} . '_total'} == 0) {
        $self->{error_msg} = "total size is 0";
        return -2;
    }
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'disks', type => 1, cb_prefix_output => 'prefix_disks_output', message_multiple => 'All storages are ok' }
    ];
    
    $self->{maps_counters}->{disks} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_disks_output {
    my ($self, %options) = @_;
    
    return "Storage '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "hostname:s"        => { name => 'hostname' },
        "remote"            => { name => 'remote' },
        "ssh-option:s@"     => { name => 'ssh_option' },
        "ssh-path:s"        => { name => 'ssh_path' },
        "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"         => { name => 'timeout', default => 30 },
        "sudo"              => { name => 'sudo' },
        "command:s"         => { name => 'command', default => 'bdf' },
        "command-path:s"    => { name => 'command_path' },
        "command-options:s" => { name => 'command_options', default => ' 2>&1' },
        "filter-fs:s"       => { name => 'filter_fs', },
        "units:s"           => { name => 'units', default => '%' },
        "free"              => { name => 'free' },
        "name:s"            => { name => 'name' },
        "regexp"              => { name => 'use_regexp' },
        "regexp-isensitive"   => { name => 'use_regexpi' },
        "space-reservation:s" => { name => 'space_reservation' },
    });

    $self->{result} = {};
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
        no_quit => 1
    );
    $self->{disks} = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    while (my $line = shift @lines) {
        # When the line is too long, the FS name is printed on a separated line
        if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
            $line .= "    ".shift @lines;
        }
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
        my ($fs, $size, $used, $available, $percent, $mount) = ($1, $2, $3, $4, $5, $6);
        
        next if (defined($self->{option_results}->{filter_fs}) && $self->{option_results}->{filter_fs} ne '' &&
            $fs !~ /$self->{option_results}->{filter_fs}/);
        
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $mount !~ /$self->{option_results}->{name}/i);
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $mount !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $mount ne $self->{option_results}->{name});
        
        $size *= 1024;
        if (defined($self->{option_results}->{space_reservation})) {
            $size = int($size - ($self->{option_results}->{space_reservation} * $size / 100));
        }
        $self->{disks}->{$mount} = { display => $mount, fs => $fs, total => $size, used => $used * 1024 };
    }
    
    if (scalar(keys %{$self->{disks}}) <= 0) {
        if ($exit_code != 0) {
            $self->{output}->output_add(long_msg => "command output:" . $stdout);
        }
        $self->{output}->add_option_msg(short_msg => "No storage found (filters or command issue)");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage usages.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'bdf').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: ' 2>&1').

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--name>

Set the storage mount point (empty means 'check all storages')

=item B<--regexp>

Allows to use regexp to filter storage mount point (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=item B<--space-reservation>

Some filesystem has space reserved (like ext4 for root).
The value is in percent of total (Default: none).

=back

=cut
