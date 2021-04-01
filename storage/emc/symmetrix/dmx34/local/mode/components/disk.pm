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

package storage::emc::symmetrix::dmx34::local::mode::components::disk;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#     ------------[ Device Information ]-------------
# 
#  RAID6 Configured:  NO
#  RAID5 Configured:  NO
#  RDF  Configured:   NO_RDF
 
#  Verify Volume Status
#     There are  16  local devices are not ready (device(DA)):-    à 0 si pas de problème
#      10000(01a) 10072(01a) 20086(01a) 1009A(01a) 200AE(01a) 100C2(01a) 100EA(01a)
#      10112(01a) 20075(01d) 10089(01d) 2009D(01d) 100B1(01d) 100C9(01d) 100F1(01d)
#      10119(01d) 20061(01d)
# 
#    No local devices have invalid tracks
# 
#  Deferred disk service is NOT enabled
# 
#  8 hot spares are configured, 1 are invoked, none are not ready  à none si pas de problème
# 
#    HotSpare 16d:D5 is invoked against  1d:D4 Time: MAR/24/16 04:48:49  à récupérer si pb
# 
#  No DAs have any volumes with Not Ready bit set
# 
#  All DAs have Write Optimize enabled
# 
#   No devices have TimeFinder Lock
# 
#   No Devices Found in Transient State

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks (1 means all)', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));
    
    if ($self->{content_file_health} !~ /----\[ Device Information(.*?)----\[/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find devices');
        return ;
    }
    
    my $content = $1;    
    $self->{components}->{disk}->{total}++;
    
    # Error if not present:
    #    No local devices have invalid tracks
    
    if ($content !~ /No local devices have invalid tracks/msi) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("problem of invalid tracks on disks"));
    } else {
        $self->{output}->output_add(long_msg => sprintf("no invalid tracks on disks"));
    }
    
    # Error if not present:
    #    All local devices are ready
    if ($content !~ /All local devices are ready/msi) {
        $content =~ /There are\s+(\S+)\s+local devices are not ready.*?\n(.*?)\n\s*\n/msi;
        my ($num, $disks) = ($1, $2);
        $disks =~ s/\n/ /msg;
        $disks =~ s/\s+/ /msg;
        $disks =~ s/^\s+//;
        $self->{output}->output_add(long_msg => sprintf("problem on following disks '%s'", $disks));
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("problem on '%s' disks", $num));
    } else {
        $self->{output}->output_add(long_msg => sprintf("all devices are ready"));
    }
    
    return if ($content !~ /(\S+) hot spares are configured,\s*(\S+)\s+are invoked,\s*(\S+)\s+are not ready/msi);
    my ($total, $used, $not_ready) = ($1, $2, $3);
    $used = 0 if ($used =~ /none/i);
    $not_ready = 0 if ($not_ready =~ /none/i);

    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'disk', instance => '1', value => $total - $used - $not_ready);

    $self->{output}->output_add(long_msg => sprintf("'%s' spare disk availables on '%s'", 
                                                    $total - $used - $not_ready, $total));
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("'%s' spare disk availables on '%s'", 
                                                    $total - $used - $not_ready, $total));
    }
    
    $self->{output}->perfdata_add(
        label => "disk_spare_available",
        nlabel => 'hardware.disk.spare.available.count',
        value => $total - $used - $not_ready,
        warning => $warn,
        critical => $crit, min => 0, max => $total
    );
}

1;
