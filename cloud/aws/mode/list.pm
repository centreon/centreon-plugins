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

package cloud::aws::mode::list;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use Switch;
use centreon::plugins::misc;
use Data::Dumper;

my @AWSServices = ['EC2', 'S3', 'RDS'];
my @EC2_instance_states = ['pending','running','shutting-down','terminated','stopping','stopped'];
my $EC2_includeallinstances = 1;

my $PAWS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.2';

    $options{options}->add_options(arguments =>
                                {
                                  "service:s@"     => { name => 'service', default => @AWSServices },
                                  "region:s"      => { name => 'region' },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{region})) {
        $self->{output}->add_option_msg(short_msg => "Please set the region. ex: --region \"eu-west-1\"");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    #my @result;

    foreach my $service (@{$self->{option_results}->{service}}) {
		$PAWS = Paws->service($service, 'region' => $self->{option_results}->{region});
		
        $self->{result}->{count}->{$service} = '0';
		switch ($service) {
			case 'EC2' { $self->EC2(); }
			case 'S3' { $self->S3(); }
			case 'RDS' { $self->RDS(); }
			else { print "previous case not true" }
		}
	}
}

sub EC2 {
	my ($self, %options) = @_;
	
	$self->{status_command} = $PAWS->DescribeInstances();
	
	# Compute data
   	foreach my $instance (@{$self->{status_command}->{Reservations}}) {
   		foreach my $tags (@{$instance->{Instances}[0]->{Tags}}){
   			if ($tags->{Key} eq 'Name'){
   				$instance->{Instances}[0]->{Name} = $tags->{Value};
   			}
   		}
   		$self->{result}->{'EC2'}->{$instance->{Instances}[0]->{InstanceId}} = {'State' => $instance->{Instances}[0]->{State}->{Name},
   			                                                                   'Name' => $instance->{Instances}[0]->{Name}
   		                                                                      };
   		
   		$self->{result}->{count}->{'EC2'}++;
	}
}

sub S3 {
	my ($self, %options) = @_;
	
	$self->{status_command} = $PAWS->ListBuckets();
	
    # Compute data
   	foreach my $bucket (@{$self->{status_command}->{Buckets}}) {
   		$self->{result}->{'S3'}->{$bucket->{Name}} = {'Creation date' => $bucket->{CreationDate}};
   		$self->{result}->{count}->{'S3'}++;
	}
}

sub RDS {
	my ($self, %options) = @_;
	
	$self->{status_command} = $PAWS->DescribeDBInstances();
	
	# Compute data
   	foreach my $dbinstance (@{$self->{status_command}->{DBInstances}}) {
   		$self->{result}->{'RDS'}->{$dbinstance->{DBInstanceIdentifier}} = {'State' => $dbinstance->{DBInstanceStatus}};
   		$self->{result}->{count}->{'RDS'}++;
	}
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();

    # Send formated data to Centreon
    foreach my $service (@{$self->{option_results}->{service}}) {
        $self->{output}->output_add(long_msg => sprintf("AWS service: %s", $service));
        foreach my $device (keys %{$self->{result}->{$service}}) {
            my $output = $device." [";
            foreach my $value (sort(keys %{$self->{result}->{$service}->{$device}})) {
            	$output = $output.$value." = ".$self->{result}->{$service}->{$device}->{$value}.", ";
            }
            $output =~ s/, $//;
            $output = $output."]";
            $self->{output}->output_add(long_msg => $output);
        }
        $self->{output}->output_add(short_msg => sprintf("%s: %s",$service,$self->{result}->{count}->{$service})
                                );
    }

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
