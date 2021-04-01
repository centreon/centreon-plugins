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

package centreon::common::emc::navisphere::mode::disk;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

my @states = (
    ['^enabled$'         , 'OK'],
    ['^binding$'         , 'OK'],
    ['^expanding$'       , 'OK'],
    ['^ready$'           , 'OK'],
    ['^unbound$'         , 'OK'],
    ['^empty$'           , 'OK'],
    ['^hot spare ready$' , 'OK'],
    ['^powering up$' , 'OK'],
    ['^requested bypass$', 'WARNING'],
    ['^equalizing$'  , 'WARNING'],
    ['^formatting$'  , 'WARNING'],
    ['^removed$'     , 'WARNING'],
    ['^unformatted$' , 'WARNING'],
    ['^failed$'      , 'CRITICAL'],
    ['^off$'         , 'CRITICAL'],
    ['^unsupported$' , 'CRITICAL'],
    ['^.*$'          , 'CRITICAL'], 
);

sub custom_threshold_check {
    my ($self, %options) = @_;

    foreach (@states) {
        if ($self->{result_values}->{state} =~ /$_->[0]/i) {
            return $_->[1];
        }
    }

    return 'ok';
}

sub custom_state_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s'", $self->{result_values}->{state});
    return $msg;
}

sub custom_state_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_utils_calc {
    my ($self, %options) = @_;

    my $diff_busy = $options{new_datas}->{$self->{instance} . '_busy_ticks'} - $options{old_datas}->{$self->{instance} . '_busy_ticks'};
    my $diff_idle = $options{new_datas}->{$self->{instance} . '_idle_ticks'} - $options{old_datas}->{$self->{instance} . '_idle_ticks'};

    if (($diff_busy + $diff_idle) == 0) {
        $self->{error_msg} = "wait new values";
        return -3;
    }
    $self->{result_values}->{utils} = $diff_busy * 100 / ($diff_busy + $diff_idle);
    $self->{result_values}->{display} =  $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are OK',  skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{disk} = [
        { label => 'state', threshold => 0,  set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_state_calc'),
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_check'),
            }
        },
        { label => 'hard-read-errors', set => {
                key_values => [ { name => 'hard_read_errors', diff => 1 }, { name => 'display' } ],
                output_template => 'Hard Read Errors : %d',
                perfdatas => [
                    { label => 'hard_read_errors', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'hard-write-errors', set => {
                key_values => [ { name => 'hard_write_errors', diff => 1 }, { name => 'display' } ],
                output_template => 'Hard Write Errors : %d',
                perfdatas => [
                    { label => 'hard_write_errors', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-io', set => {
                key_values => [ { name => 'read_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read_io', template => '%s',
                      min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-io', set => {
                key_values => [ { name => 'write_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write I/O : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write_io', template => '%s',
                      min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'utils', set => {
                key_values => [ { name => 'busy_ticks', diff => 1 }, { name => 'idle_ticks', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_utils_calc'),
                output_template => 'Utils : %.2f %%', output_use => 'utils',
                perfdatas => [
                    { label => 'utils', value => 'utils', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-raidgroupid:s' => { name => 'filter_raidgroupid', },
        'filter-disk:s'        => { name => 'filter_disk', },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{disk} = {};
    $self->{cache_name} = "cache_clariion_" . $options{custom}->{hostname}  . '_' . $options{custom}->{mode} . '_' .
        (defined($self->{option_results}->{filter_disk}) ? md5_hex($self->{option_results}->{filter_disk}) : md5_hex('all'));
    
    my $response = $options{custom}->execute_command(cmd => 'getdisk -state -bytrd -bytwrt -hw -hr -busyticks -idleticks -rg');

    #Bus 1 Enclosure 7  Disk 13
    #State:                   Enabled
    #Kbytes Read:             1109878030
    #Kbytes Written:          0
    #Hard Write Errors:       0
    #Hard Read Errors:        0
    #Busy Ticks:              462350
    #Idle Ticks:              388743630
    #Raid Group ID:           0

    # Add a "\n" for the end.
    $response .= "\n";
    while ($response =~ /^Bus\s+(\S+)\s+Enclosure\s+(\S+)\s+Disk\s+(\S+)(.*?)\n\n/msgi) {
        my $disk_instance = "$1_$2_$3";
        my $values = $4;
        
        # First Filters
        if (defined($self->{option_results}->{filter_disk}) && $self->{option_results}->{filter_disk} ne '' &&
            $disk_instance !~ /$self->{option_results}->{filter_disk}/) {
            $self->{output}->output_add(long_msg => "skipping disk '" . $disk_instance . "': no matching filter disk", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_raidgroupid}) && $self->{option_results}->{filter_raidgroupid} ne '' &&
            $values =~ /^Raid Group ID:\s+(\S+)/mi && $1 !~ /$self->{option_results}->{filter_raidgroupid}/) {
            $self->{output}->output_add(long_msg => "skipping disk '" . $disk_instance . "': no matching filter raid group id", debug => 1);
            next;
        }
        
        my $datas = {};
        while ($values =~ /^([^\n]*?):(.*?)\n/msgi) {
            $datas->{centreon::plugins::misc::trim(lc($1))} = centreon::plugins::misc::trim($2);
        }
        
        $self->{disk}->{$disk_instance} = {
            display => $disk_instance,
            state => $datas->{state},
            hard_read_errors => $datas->{'hard read errors'},
            hard_write_errors => $datas->{'hard write errors'},
            read_io => defined($datas->{'kbytes read'}) ? $datas->{'kbytes read'} * 1024 : undef,
            write_io => defined($datas->{'kbytes write'}) ? $datas->{'kbytes write'} * 1024 : undef,
            busy_ticks => $datas->{'busy ticks'},
            idle_ticks => $datas->{'idle ticks'},
        };
    }
}

1;

__END__

=head1 MODE

Check the status of the physical disks.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read-errors', 'write-errors', 'read-io', 'write-io', 'utils'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-errors', 'write-errors', 'read-io', 'write-io', 'utils'.

=item B<--filter-disk>

Filter Disk (regexp can be used).
Example: 1_7_14 ([BUS]_[ENCLOSURE]_[DISK]).

=item B<--filter-raidgroupid>

Filter Raid Group ID (regexp can be used).
Example: N/A or a number.

=back

=cut
