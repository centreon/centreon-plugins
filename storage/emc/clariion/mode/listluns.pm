###############################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Florian Asche <info@florian-asche.de>
#
# Based on De Bodt Lieven plugin
# Based on Apache Mode by Simon BOMM
####################################################################################

package storage::emc::clariion::mode::listluns;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
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
        
        next if (defined($self->{option_results}->{filter_lunnumber}) && $self->{option_results}->{filter_lunnumber} ne '' &&
                 $lun_num !~ /$self->{option_results}->{filter_lunnumber}/);
        next if (defined($self->{option_results}->{filter_lunstate}) && $self->{option_results}->{filter_lunstate} ne '' &&
                 $state !~ /$self->{option_results}->{filter_lunstate}/);
        next if (defined($self->{option_results}->{filter_drivetype}) && $self->{option_results}->{filter_drivetype} ne '' &&
                 $drive_type !~ /$self->{option_results}->{filter_drivetype}/);
        next if (defined($self->{option_results}->{filter_raidtype}) && $self->{option_results}->{filter_raidtype} ne '' &&
                 $raid_type !~ /$self->{option_results}->{filter_raidtype}/);
        next if (defined($self->{option_results}->{filter_raidgroupid}) && $self->{option_results}->{filter_raidgroupid} ne '' &&
                 $raid_group_id !~ /$self->{option_results}->{filter_raidgroupid}/);

        $self->{result}->{$lun_num} = {state => $state, drive_type => $drive_type, raid_type => $raid_type, raid_groupid => $raid_group_id};
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{clariion} = $options{custom};
    
    $self->manage_selection();

    my $lun_display = '';
    my $lun_display_append = '';
    foreach my $num (sort(keys %{$self->{result}})) {
        $lun_display .= $lun_display_append . 'number = ' . $num . 
                               ' [' .
                               'state = ' . $self->{result}->{$num}->{state} .
                               ', drive type = ' . $self->{result}->{$num}->{drive_type} .
                               ', raid type = ' . $self->{result}->{$num}->{raid_type} .
                               ', raid groupid = ' . $self->{result}->{$num}->{raid_groupid} .
                               ']';
        $lun_display_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List LUNs: ' . $lun_display);
    $self->{output}->display(nolabel => 1);
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

=item B<--filter-raidtype>

Filter Raid Group ID (regexp can be used).
Example: N/A or a number.

=back

=cut
