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

package apps::lync::mode::lyncusers;

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
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "warning-unique:s"        => { name => 'warning_unique', },
                                  "critical-unique:s"       => { name => 'critical_unique', },                                                                                                      
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
    if (($self->{perfdata}->threshold_validate(label => 'warning-unique', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-unique', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    $self->{sql}->query(query => q{Select 
                                        (cast (RE.ClientApp as varchar (100))) as ClientVersion, 
                                        R.UserAtHost as UserName, 
                                        Reg.Fqdn
                                    From 
                                        rtcdyn.dbo.RegistrarEndpoint RE 
                                    Inner Join 
                                        rtc.dbo.Resource R on R.ResourceId = RE.OwnerId 
                                    Inner Join 
                                        rtcdyn.dbo.Registrar Reg on Reg.RegistrarId = RE.PrimaryRegistrarClusterId 
                                    Order By ClientVersion, UserName } 
                        );
    my $users = $self->{sql}->fetchrow_array();

    $self->{sql}->query(query => q{Select 
                                        count(*) as totalonline, count(distinct UserAtHost) as totalunique
                                   From 
                                       rtcdyn.dbo.RegistrarEndpoint RE
                                   Inner Join
                                       rtc.dbo.Resource R on R.ResourceId = RE.OwnerId
                                   Inner Join
                                       rtcdyn.dbo.Registrar Reg on Reg.RegistrarId = RE.PrimaryRegistrarClusterId}
                        );
    my $unique_users = $self->{sql}->fetchrow_array();

    my $exit1 = $self->{perfdata}->threshold_check(value => $unique_users, threshold => [ { label => 'critical-unique', 'exit_litteral' => 'critical' }, { label => 'warning-unique', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $users, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $exit_code = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]); 

    $self->{output}->output_add(severity => $exit_code,
                                  short_msg => sprintf("%i lync unique user(s). (%i total users)", $unique_users, $users));
    $self->{output}->perfdata_add(label => 'unique_users',
                                  value => $unique_users,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-unique'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-unique'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'total_users',
                                  value => $users,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Lync users and unique users (one user can be connected with several devices) -- use with dyn-mode mssql plugin)

=over 8

=item B<--warning>

Threshold warning on total users

=item B<--critical>

Threshold critical on total users

=item B<--warning-unique>

Threshold warning on unique users

=item B<--critical-unique>

Threshold critical on unique users


=back

=cut
