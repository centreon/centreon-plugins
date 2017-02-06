#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::ucopia::wlc::snmp::mode::users;

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
                                  "warning:s"   => { name => 'warning' },
                                  "critical:s"   => { name => 'critical' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $oid_totalConnectedUsers = '.1.3.6.1.4.1.31218.3.1.0';
    my $oid_licenceUsers = '.1.3.6.1.4.1.31218.3.5.0';

    my $result = $options{snmp}->get_leef(oids => [$oid_totalConnectedUsers, $oid_licenceUsers], nothing_quit => 1);
    my $exit = $self->{perfdata}->threshold_check(value => $result->{$oid_totalConnectedUsers}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $result->{$oid_licenceUsers} = undef if ($result->{$oid_licenceUsers} == 0);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("'%d' connected users (Available licence: %s)", 
                                                $result->{$oid_totalConnectedUsers},
                                                defined($result->{$oid_licenceUsers}) ? $result->{$oid_licenceUsers} : '-'));
    $self->{output}->perfdata_add(value => $result->{$oid_totalConnectedUsers}, label => 'users',
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => $result->{$oid_licenceUsers});

   $self->{output}->display();
   $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check connected users.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
    
