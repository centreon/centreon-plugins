#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::common::ive::mode::users;

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
                                  "warning-web:s"       => { name => 'warning_web' },
                                  "critical-web:s"      => { name => 'critical_web' },
                                  "warning-meeting:s"   => { name => 'warning_meeting' },
                                  "critical-meeting:s"  => { name => 'critical_meeting' },
                                  "warning-node:s"      => { name => 'warning_node' },
                                  "critical-node:s"     => { name => 'critical_node' },
                                  "warning-cluster:s"   => { name => 'warning_cluster' },
                                  "critical-cluster:s"  => { name => 'critical_cluster' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_web', value => $self->{option_results}->{warning_web})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning web threshold '" . $self->{option_results}->{warning_web} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_web', value => $self->{option_results}->{critical_web})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical web threshold '" . $self->{option_results}->{critical_web} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_meeting', value => $self->{option_results}->{warning_meeting})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning meeting threshold '" . $self->{option_results}->{warning_meeting} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_meeting', value => $self->{option_results}->{critical_meeting})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical meeting threshold '" . $self->{option_results}->{critical_meeting} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_node', value => $self->{option_results}->{warning_node})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning node threshold '" . $self->{option_results}->{warning_node} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_node', value => $self->{option_results}->{critical_node})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical node threshold '" . $self->{option_results}->{critical_node} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_cluster', value => $self->{option_results}->{warning_cluster})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning cluster threshold '" . $self->{option_results}->{warning_cluster} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_cluster', value => $self->{option_results}->{critical_cluster})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical cluster threshold '" . $self->{option_results}->{critical_cluster} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_signedInWebUsers = '.1.3.6.1.4.1.12532.2.0';
    my $oid_meetingUserCount = '.1.3.6.1.4.1.12532.9.0';
    my $oid_iveConcurrentUsers = '.1.3.6.1.4.1.12532.12.0';
    my $oid_clusterConcurrentUsers = '.1.3.6.1.4.1.12532.13.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_signedInWebUsers, $oid_meetingUserCount, 
                                                  $oid_iveConcurrentUsers, $oid_clusterConcurrentUsers], nothing_quit => 1);
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $result->{$oid_signedInWebUsers}, 
                                        threshold => [ { label => 'critical_web', 'exit_litteral' => 'critical' }, { label => 'warning_web', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $result->{$oid_meetingUserCount}, 
                                        threshold => [ { label => 'critical_meeting', 'exit_litteral' => 'critical' }, { label => 'warning_meeting', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $result->{$oid_iveConcurrentUsers}, 
                                        threshold => [ { label => 'critical_node', 'exit_litteral' => 'critical' }, { label => 'warning_node', exit_litteral => 'warning' } ]);
    my $exit4 = $self->{perfdata}->threshold_check(value => $result->{$oid_clusterConcurrentUsers}, 
                                        threshold => [ { label => 'critical_cluster', 'exit_litteral' => 'critical' }, { label => 'warning_cluster', exit_litteral => 'warning' } ]);
                                        
    $self->{output}->output_add(severity => $exit1,
                                short_msg => sprintf("Current concurrent signed-in web users connections: %d",
                                                     $result->{$oid_signedInWebUsers}));
    $self->{output}->output_add(severity => $exit2,
                                short_msg => sprintf("Current concurrent meeting users connections: %s",
                                                     defined($result->{$oid_meetingUserCount}) ? $result->{$oid_meetingUserCount} : 'unknown'));
    $self->{output}->output_add(severity => $exit3,
                                short_msg => sprintf("Current concurrent node logged users connections: %d",
                                                     $result->{$oid_iveConcurrentUsers}));
    $self->{output}->output_add(severity => $exit4,
                                short_msg => sprintf("Current concurrent cluster logged users connections: %d",
                                                     $result->{$oid_clusterConcurrentUsers}));                                       
                                                     
    $self->{output}->perfdata_add(label => "web",
                                  value => $result->{$oid_signedInWebUsers},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_web'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_web'),
                                  min => 0);
    $self->{output}->perfdata_add(label => "meeting",
                                  value => $result->{$oid_meetingUserCount},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_meeting'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_meeting'),
                                  min => 0);
    $self->{output}->perfdata_add(label => "node",
                                  value => $result->{$oid_iveConcurrentUsers},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_node'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_node'),
                                  min => 0);
    $self->{output}->perfdata_add(label => "cluster",
                                  value => $result->{$oid_clusterConcurrentUsers},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_cluster'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_cluster'),
                                  min => 0);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check users connections (web users, cluster users, node users, meeting users) (JUNIPER-IVE-MIB).

=over 8

=item B<--warning-web>

Threshold warning for users connected and uses the web feature.

=item B<--critical-web>

Threshold critical for users connected and uses the web feature.

=item B<--warning-meeting>

Threshold warning for secure meeting users connected.

=item B<--critical-meeting>

Threshold critical for secure meeting users connected.

=item B<--warning-node>

Threshold warning for users in this node that are logged in.

=item B<--critical-node>

Threshold critical for users in this node that are logged in.

=item B<--warning-cluster>

Threshold warning for users in this cluster that are logged in.

=item B<--critical-cluster>

Threshold critical for users in this cluster that are logged in.

=back

=cut
    