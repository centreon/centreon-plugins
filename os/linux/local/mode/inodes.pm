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

package os::linux::local::mode::inodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'inodes', type => 1, cb_prefix_output => 'prefix_inodes_output', message_multiple => 'All inode partitions are ok' }
    ];
    
    $self->{maps_counters}->{inodes} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'display' } ],
                output_template => 'used: %s %%',
                perfdatas => [
                    { label => 'used', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_inodes_output {
    my ($self, %options) = @_;

    return "Inodes partition '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-type:s'       => { name => 'filter_type', },
        'filter-fs:s'         => { name => 'filter_fs', },
        'filter-mountpoint:s' => { name => 'filter_mountpoint' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = $options{custom}->execute_command(
        command => 'df',
        command_options => '-P -i -T 2>&1',
        no_quit => 1
    );

    $self->{inodes} = {};
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(.*)/);
        my ($fs, $type, $size, $used, $available, $percent, $mount) = ($1, $2, $3, $4, $5, $6, $7);

        next if (defined($self->{option_results}->{filter_fs}) && $self->{option_results}->{filter_fs} ne '' &&
            $fs !~ /$self->{option_results}->{filter_fs}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/);
        next if (defined($self->{option_results}->{filter_mountpoint}) && $self->{option_results}->{filter_mountpoint} ne '' &&
            $mount !~ /$self->{option_results}->{filter_mountpoint}/);

        $percent =~ s/%//g;
        next if ($percent eq '-');
        $self->{inodes}->{$mount} = { display => $mount, fs => $fs, type => $type, total => $size, used => $percent };
    }

    if (scalar(keys %{$self->{inodes}}) <= 0) {
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

Check Inodes space usage on partitions.

Command used: df -P -i -T 2>&1

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=item B<--filter-mountpoint>

Filter filesystem mount point (regexp can be used).

=item B<--filter-type>

Filter filesystem type (regexp can be used).

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=back

=cut
