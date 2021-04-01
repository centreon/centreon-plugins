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

package os::aix::local::mode::inodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'inodes', type => 1, cb_prefix_output => 'prefix_inodes_output', message_multiple => 'All inode partitions are ok' }
    ];

    $self->{maps_counters}->{inodes} = [
        { label => 'usage', nlabel => 'storage.inodes.usage.percentage', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'used: %s %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-fs:s'    => { name => 'filter_fs' },
        'filter-mount:s' => { name => 'filter_mount' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = $options{custom}->execute_command(
        command => 'df',
        command_options => '-i -v 2>&1'
    );

    $self->{inodes} = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        # Can be very different.
        #Filesystem    512-blocks      Used      Free %Used    Iused    Ifree %Iused Mounted on
        #/dev/hd4         1048576    118408    930168   12%     3699   104325     4% /
        #
        #Filesystem 512-blocks Free   %Used   Iused  %Iused  Mounted on
        #/dev/hd0    19368     9976    48%     4714    5%     /

        next if ($line !~ /^(\S+)/);
        my $fs = $1;
        next if ($line !~ /(\d+)%\s+([^%]*?)$/);
        my ($ipercent, $mount) = ($1, $2);

        next if (defined($self->{option_results}->{filter_fs}) && $self->{option_results}->{filter_fs} ne '' &&
            $fs !~ /$self->{option_results}->{filter_fs}/);
        next if (defined($self->{option_results}->{filter_mount}) && $self->{option_results}->{filter_mount} ne '' &&
            $mount !~ /$self->{option_results}->{filter_mount}/);

        $self->{inodes}->{$mount} = { display => $mount, used => $ipercent };
    }
    
    if (scalar(keys %{$self->{inodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage found (filters or command issue)");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check inodes usage on partitions.
Command used: df -i -v 2>&1

=over 8

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=item B<--filter-mount>

Filter mountpoint (regexp can be used).

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=back

=cut
