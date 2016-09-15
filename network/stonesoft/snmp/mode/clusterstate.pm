#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::stonesoft::snmp::mode::clusterstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %oper_state = (
    0 => ['unknown', 'UNKNOWN'],
    1 => ['online', 'OK'], 
    2 => ['goingOnline', 'WARNING'], 
    3 => ['lockedOnline', 'WARNING'],
    4 => ['goingLockedOnline', 'WARNING'],
    5 => ['offline', 'CRITICAL'],
    6 => ['goingOffline', 'CRITICAL'],
    7 => ['lockedOffline', 'CRITICAL'],
    8 => ['goingLockedOffline', 'CRITICAL'],
    9 => ['standby', 'CRITICAL'],
    10 => ['goingStandby', 'CRITICAL'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
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

    my $oid_nodeMemberId = '.1.3.6.1.4.1.1369.6.1.1.2.0';
    my $oid_nodeOperState = '.1.3.6.1.4.1.1369.6.1.1.3.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_nodeMemberId, $oid_nodeOperState], nothing_quit => 1);
    
    $self->{output}->output_add(severity => ${$oper_state{$result->{$oid_nodeOperState}}}[1],
                                short_msg => sprintf("Node status is '%s' [Member id : %s]", 
                                            ${$oper_state{$result->{$oid_nodeOperState}}}[0],
                                            $result->{$oid_nodeMemberId}));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check status of clustered node.

=over 8

=back

=cut
    
