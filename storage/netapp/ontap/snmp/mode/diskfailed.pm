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

package storage::netapp::ontap::snmp::mode::diskfailed;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_diskFailedCount = '.1.3.6.1.4.1.789.1.6.4.7.0';
    my $oid_diskFailedMessage = '.1.3.6.1.4.1.789.1.6.4.10.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_diskFailedCount], nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Disks are ok.');
    if ($result->{$oid_diskFailedCount} != 0) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("'%d' disks are failed [message: %s].", 
                                                    $result->{$oid_diskFailedCount}, 
                                                    defined($result->{$oid_diskFailedMessage}) ? $result->{$oid_diskFailedMessage} : '-'));
    }

    $self->{output}->perfdata_add(label => 'failed',
                                  value => $result->{$oid_diskFailedCount},
                                  min => 0);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the current number of disk broken.
If you are in cluster mode, the following mode doesn't work. Ask to netapp to add it :)

=over 8

=back

=cut
    
