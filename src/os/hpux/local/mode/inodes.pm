#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package os::hpux::local::mode::inodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub prefix_inodes_output {
    my ($self, %options) = @_;
    
    return "Inodes partition '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'inodes', type => 1, cb_prefix_output => 'prefix_inodes_output', message_multiple => 'All partitions inodes usage are ok' }
    ];
    
    $self->{maps_counters}->{inodes} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'display' } ],
                output_template => 'Used: %s %%',
                perfdatas => [
                    { label => 'used', template => '%d', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-fs:s'        => { name => 'filter_fs', },
        'name:s'             => { name => 'name' },
        'regexp'             => { name => 'use_regexp' },
        'regexp-isensitive'  => { name => 'use_regexpi' }, # compatibility
        'regexp-insensitive' => { name => 'use_regexpi' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = $options{custom}->execute_command(
        command => 'bdf',
        command_options => '-i 2>&1',
        no_quit => 1
    );

    $self->{inodes} = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    while (my $line = shift @lines) {
        # When the line is too long, the FS name is printed on a separated line
        if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
            $line .= "    " . shift @lines;
        }
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
        my ($fs, $size, $used, $available, $percent, $iused, $ifree, $ipercent, $mount) = ($1, $2, $3, $4, $5, $6, $7, $8, $9);

        next if (defined($self->{option_results}->{filter_fs}) && $self->{option_results}->{filter_fs} ne '' &&
            $fs !~ /$self->{option_results}->{filter_fs}/);

        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $mount !~ /$self->{option_results}->{name}/i);
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $mount !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $mount ne $self->{option_results}->{name});

        $ipercent =~ s/%//g;
        $self->{inodes}->{$mount} = { display => $mount, used => $ipercent };
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

Check inodes usage on partitions.

Command used: bdf -i 2>&1

=over 8

=item B<--warning-usage>

Warning threshold in percent.

=item B<--critical-usage>

Critical threshold in percent.

=item B<--name>

Set the storage mount point (empty means 'check all storages')

=item B<--regexp>

Allows to use regexp to filter storage mount point (with option --name).

=item B<--regexp-insensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=back

=cut
