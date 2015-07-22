################################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an executable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting executable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : David Sabatié <dsabatie@centren.com>
#
####################################################################################

package cloud::aws::mode::test;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Data::Dumper;
use JSON;

my @EC2_instance_states = ['pending','running','shutting-down','terminated','stopping','stopped'];
my $EC2_includeallinstances = 1;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.2';

    $options{options}->add_options(arguments =>
                                {
                                  "service:s@"     => { name => 'service', default => ['EC2'] },
                                  "region:s"      => { name => 'region' },
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
    my @result;

    my $Instance = Paws->service('CloudWatch', 'region' => $self->{option_results}->{region});
    $self->{status_command} = $Instance->ListMetrics('Namespace' => 'AWS/EC2', 'Dimensions' => [{'Value' => 'i-330eacd5', 'Name' => 'InstanceId'}]);

print Dumper($self->{status_command}->{Metrics});

#$self->{status_command} = $Instance->GetMetricStatistics('MetricName' => 'NetworkIn');
#
#print Dumper($self->{status_command});
exit;
    # Compute data
    $self->{option_results}->{instancecount}->{'total'} = '0';
    foreach my $curstate (@EC2_instance_states){
    	$self->{option_results}->{instancecount}->{$curstate} = '0';
    }

   	foreach my $instance (@{$self->{status_command}->{Reservations}}) {
   		foreach my $tags (@{$instance->{Instances}[0]->{Tags}}){
   			if ($tags->{Key} eq 'Name'){
   				$instance->{Instances}[0]->{Name} = $tags->{Value};
   			}
   		}
   		$self->{result}->{instances}->{$instance->{Instances}[0]->{InstanceId}} = {'InstanceState' => $instance->{Instances}[0]->{State}->{Name},
   			                                                                       'InstanceName' => $instance->{Instances}[0]->{Name}
   		                                                                          };
   		foreach my $curstate (@EC2_instance_states){
   			if($instance->{Instances}[0]->{State}->{Name} eq $curstate){
   				$self->{option_results}->{instancecount}->{$curstate}++;
   			}
   		}
   		$self->{option_results}->{instancecount}->{'total'}++;
	}
}

sub run {
    my ($self, %options) = @_;

    my $msg;
    my $old_status = 'ok';

    $self->manage_selection();

    # Send formated data to Centreon
    my $exit_code = $self->{perfdata}->threshold_check(value => $self->{option_results}->{instancecount}->{'total'},
                              threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
	
	$self->{output}->perfdata_add(label => 'total instances',
                                  value => $self->{option_results}->{instancecount}->{'total'},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
                                  
    foreach my $curstate (@EC2_instance_states){
    	$self->{output}->perfdata_add(label => $curstate.' instances',
                                  value => $self->{option_results}->{instancecount}->{$curstate},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    }

    foreach my $instance (keys %{$self->{result}->{instances}}) {
        $self->{output}->output_add(long_msg => sprintf("%s [id = %s , state = %s]",
                                                        $self->{result}->{instances}->{$instance}->{InstanceName}, $instance, $self->{result}->{instances}->{$instance}->{InstanceState}));
    }
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Total instances: %s", $self->{option_results}->{instancecount}->{'total'})
                                );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Show number of current active calls

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--remote>

Execute command remotely; can be 'ami' or 'ssh' (default: ssh).

=item B<--hostname>

Hostname to query (need --remote option).

=item B<--port>

AMI remote port (default: 5038).

=item B<--username>

AMI username.

=item B<--password>

AMI password.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to get information (Default: 'asterisk_sendcommand.pm').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: /home/centreon/bin).

=back

=cut
