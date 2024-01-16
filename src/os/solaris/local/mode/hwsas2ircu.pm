#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package os::solaris::local::mode::hwsas2ircu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'sas2ircu',
        command_options => 'LIST 2>&1',
        command_path => '/usr/bin'
    );

    $self->{output}->output_add(
        severity => 'OK', 
        short_msg => "No problems on volumes"
    );

    while (($stdout =~ /^\s*Index.*?\n.*?\n\s+(\d+)\s+/imsg)) {
        # Index    Type          ID      ID    Pci Address          Ven ID  Dev ID
        # -----  ------------  ------  ------  -----------------    ------  ------
        #   0     SAS2008     1000h    72h   00h:04h:00h:00h      1000h   0072h
        #
        #        Adapter      Vendor  Device                       SubSys  SubSys
        # Index    Type          ID      ID    Pci Address          Ven ID  Dev ID
        # -----  ------------  ------  ------  -----------------    ------  ------
        #   1     SAS2008     1000h    72h   00h:0bh:00h:00h      1000h   0072h
        #SAS2IRCU: Utility Completed Successfully.
        my $index = $1;

        my ($stdout2) = $options{custom}->execute_command(
            command => 'sas2ircu',
            command_options => sprintf('%s DISPLAY 2>&1', $index),
            command_path => '/usr/bin'
        );
        
        #IR Volume information
        #------------------------------------------------------------------------
        #IR volume 1
        #  Volume ID                               : 905
        #  Volume Name                             : test
        #  Status of volume                        : Okay (OKY)
        #  RAID level                              : RAID1
        #  Size (in MB)                            : 68664
        #  Physical hard disks                     :
        #  PHY[0] Enclosure#/Slot#                 : 1:2
        #  PHY[1] Enclosure#/Slot#                 : 1:3
        #------------------------------------------------------------------------
        #Physical device information

        if ($stdout2 =~ /^IR Volume information(.*)Physical device information/ims) {
            my @content = split(/\n/, $1);
            shift @content;
            my $volume_name = '';
            foreach my $line (@content) {

                next if ($line =~ /^---/);

                if ($line =~ /Volume Name\s+:\s+(.*)/i) {
                    $volume_name = $1;
                    $volume_name = centreon::plugins::misc::trim($volume_name);
                    next;
                }

                if ($line =~ /Status of volume\s+:\s+(.*)(\n|\()/i) {
                    my $status_volume = $1;
                    $status_volume = centreon::plugins::misc::trim($status_volume);
                    if ($status_volume !~ /Okay/i) {
                        $self->{output}->output_add(
                            severity => 'CRITICAL', 
                            short_msg => "Volume 'volume_name' status is '$status_volume'"
                        );
                    }
                }
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check hardware raid status (use 'sas2ircu' command).

Command used: '/usr/bin/sas2ircu LIST 2>&1' and '/usr/bin/sas2ircu %(index) DISPLAY 2>&1'

=over 8

=back

=cut
