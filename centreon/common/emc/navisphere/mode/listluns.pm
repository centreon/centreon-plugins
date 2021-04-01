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

package centreon::common::emc::navisphere::mode::listluns;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
            {
                "filter-lunnumber:s"        => { name => 'filter_lunnumber', },
                "filter-lunstate:s"         => { name => 'filter_lunstate', },
                "filter-drivetype:s"        => { name => 'filter_drivetype', },
                "filter-raidtype:s"         => { name => 'filter_raidtype', },
                "filter-raidgroupid:s"      => { name => 'filter_raidgroupid', },
            });

    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $self->{clariion}->execute_command(cmd => 'getlun -uid -state -rg -type -drivetype -capacity');
    
    $| = 1;
    while ($response =~ /^(LOGICAL UNIT NUMBER.*?\n\n)/imsg) {
        #LOGICAL UNIT NUMBER 4088
        #UID:                        60:06:01:60:F8:C0:1E:00:58:68:46:25:C3:14:E1:11
        #State:                      Bound
        #RAIDGroup ID:               14
        #RAID Type:                  RAID5
        #Drive Type:                 SATAII
        #LUN Capacity(Megabytes):    2817458
        #LUN Capacity(Blocks):       5770154496

        #LOGICAL UNIT NUMBER 11
        #UID:                        60:06:01:60:F8:C0:1E:00:FA:01:AE:2B:27:AF:E3:11
        #State:                      Bound
        #RAIDGroup ID:               N/A
        #RAID Type:                  N/A
        #Drive Type:                 N/A
        #LUN Capacity(Megabytes):    6339281
        #LUN Capacity(Blocks):       12982847616
        
        my $content = $1;
        my ($lun_num, $raid_type, $raid_group_id, $drive_type, $state);
        $lun_num = $1 if ($content =~ /^LOGICAL UNIT NUMBER\s+(\d+)/im);
        $state = $1 if ($content =~ /^State:\s+(.*)$/im);
        $raid_type = $1 if ($content =~ /^RAID Type:\s+(.*)$/im);
        $raid_group_id = $1 if ($content =~ /^RAIDGroup ID:\s+(.*)$/im);
        $drive_type = $1 if ($content =~ /^Drive Type:\s+(.*)$/im);
        
        if (defined($self->{option_results}->{filter_lunnumber}) && $self->{option_results}->{filter_lunnumber} ne '' &&
            $lun_num !~ /$self->{option_results}->{filter_lunnumber}/) {
            $self->{output}->output_add(long_msg => "Skipping lun '" . $lun_num . "': no matching filter lun number");
            next;
        }
        if (defined($self->{option_results}->{filter_lunstate}) && $self->{option_results}->{filter_lunstate} ne '' &&
            $state !~ /$self->{option_results}->{filter_lunstate}/) {
            $self->{output}->output_add(long_msg => "Skipping lun '" . $lun_num . "': no matching filter lun state");
            next;
        }
        if (defined($self->{option_results}->{filter_drivetype}) && $self->{option_results}->{filter_drivetype} ne '' &&
            $drive_type !~ /$self->{option_results}->{filter_drivetype}/) {
            $self->{output}->output_add(long_msg => "Skipping lun '" . $lun_num . "': no matching filter lun drive type");
            next;
        }
        if (defined($self->{option_results}->{filter_raidtype}) && $self->{option_results}->{filter_raidtype} ne '' &&
            $raid_type !~ /$self->{option_results}->{filter_raidtype}/) {
            $self->{output}->output_add(long_msg => "Skipping lun '" . $lun_num . "': no matching filter lun raid type");
            next;
        }
        if (defined($self->{option_results}->{filter_raidgroupid}) && $self->{option_results}->{filter_raidgroupid} ne '' &&
            $raid_group_id !~ /$self->{option_results}->{filter_raidgroupid}/) {
            $self->{output}->output_add(long_msg => "Skipping lun '" . $lun_num . "': no matching filter lun raid group id");
            next;
        }

        $self->{result}->{$lun_num} = {state => $state, drive_type => $drive_type, raid_type => $raid_type, raid_groupid => $raid_group_id};
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{clariion} = $options{custom};
    
    $self->manage_selection();
    foreach my $num (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => "'" . $num . "' [state = " . $self->{result}->{$num}->{state} .
                                                '] [drive type = ' . $self->{result}->{$num}->{drive_type} .
                                                '] [raid type = ' . $self->{result}->{$num}->{raid_type} .
                                                '] [raid groupid = ' . $self->{result}->{$num}->{raid_groupid} .
                                                ']');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List LUNs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['number', 'state', 'drive_type', 'raid_type', 'raid_groupid']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{clariion} = $options{custom};

    $self->manage_selection();
    foreach my $num (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(number => $num,
                                         state => $self->{result}->{$num}->{state},
                                         drive_type => $self->{result}->{$num}->{drive_type},
                                         raid_type => $self->{result}->{$num}->{raid_type},
                                         raid_groupid => $self->{result}->{$num}->{raid_groupid},
                                         );
    }
}

1;

__END__

=head1 MODE

List Logical Units (LUNs).

=over 8

=item B<--filter-lunnumber>

Filter Lun Number (regexp can be used).

=item B<--filter-lunstate>

Filter Lun State (regexp can be used).
Example: Bound, Faulted, Expanding,...

=item B<--filter-drivetype>

Filter Drive types (regexp can be used).
Example: N/A, SATAII, Fibre Channel,...

=item B<--filter-raidtype>

Filter Raid types (regexp can be used).
Example: N/A, Hot Spare, RAID5,...

=item B<--filter-raidgroupid>

Filter Raid Group ID (regexp can be used).
Example: N/A or a number.

=back

=cut
