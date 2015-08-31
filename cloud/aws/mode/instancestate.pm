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

package cloud::aws::mode::instancestate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Data::Dumper;
use JSON;

my %EC2_instance_states = ('pending' => 'WARNING',
                           'running' => 'OK',
                           'shutting-down' => 'CRITICAL',
                           'terminated' => 'CRITICAL',
                           'stopping' => 'CRITICAL',
                           'stopped' => 'CRITICAL'
);
my $EC2_includeallinstances = 1;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.2';

    $options{options}->add_options(arguments =>
                                {
                                  "state:s"     => { name => 'state', default => 'all' },
                                  "no-includeallinstances"     => { name => 'includeallinstances' },
                                  "region:s"      => { name => 'region' },
                                  "exclude:s"     => { name => 'exclude' },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
#    if (!defined($self->{option_results}->{region})) {
#        $self->{output}->add_option_msg(severity => 'UNKNOWN',
#	       								short_msg => "Please set the region. ex: --region \"eu-west-1\"");
#        $self->{output}->option_exit();
#    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my @result;

	# Getting some parameters
	# includeallinstances
	if (defined($self->{option_results}->{includeallinstances})) {
		$self->{option_results}->{includeallinstances} = 0;
	}
	else {
		$self->{option_results}->{includeallinstances} = $EC2_includeallinstances;
	}
	
	# states
	if ($self->{option_results}->{state} eq 'all'){
		@{$self->{option_results}->{statetab}} = keys(%EC2_instance_states);
    }
    else {
    	@{$self->{option_results}->{statetab}} = split(/,/, $self->{option_results}->{state});
    	foreach my $curstate (@{$self->{option_results}->{statetab}}) {
    		if (! grep { /^$curstate$/ } keys(%EC2_instance_states) ) {
	       		$self->{output}->add_option_msg(severity => 'UNKNOWN',
	       										short_msg => "The state doesn't exist.");
        		$self->{output}->option_exit();
	    	}
    	}
    }
    
    # exclusions
    if (defined($self->{option_results}->{exclude})){
    	my @excludetab = split(/,/, $self->{option_results}->{exclude});
		my %array1 = map { $_ => 1 } @excludetab;
		@{$self->{option_results}->{statetab}} = grep { not $array1{$_} } @{$self->{option_results}->{statetab}};
    }
    
    # Getting data from AWS
    # Build command
    my $awscommand = "aws ec2 describe-instance-status ";
    if ($self->{option_results}->{includeallinstances}) {
    	$awscommand = $awscommand . "--include-all-instances ";
    }
    if ($self->{option_results}->{region}) {
    	$awscommand = $awscommand . "--region ".$self->{option_results}->{region}." ";
    }
    $awscommand = $awscommand . "--filters Name=instance-state-name,Values=";
    foreach my $filter (@{$self->{option_results}->{statetab}}) {
    	$awscommand = $awscommand . $filter . ",";
    }
    chop($awscommand);
    
    # Exec command
    my $jsoncontent = `$awscommand`;
    if ($? > 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot run aws");
        $self->{output}->option_exit();
    }
    my $json = JSON->new;
    eval {
        $self->{command_return} = $json->decode($jsoncontent);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json answer");
        $self->{output}->option_exit();
    }

    # Compute data
    $self->{option_results}->{instancecount}->{'total'} = '0';
    foreach my $curstate (@{$self->{option_results}->{statetab}}){
    	$self->{option_results}->{instancecount}->{$curstate} = '0';
    }
   	foreach my $l (@{$self->{command_return}->{InstanceStatuses}}) {
   		$self->{result}->{instance}->{$l->{InstanceId}} = $l->{InstanceState}->{Name};
   		
   		# long output for each instance
   		$self->{output}->output_add(long_msg => "'" . $l->{InstanceId} . "' [state = " . $l->{InstanceState}->{Name} . ']');
   		
   		foreach my $curstate (@{$self->{option_results}->{statetab}}){
   			if($l->{InstanceState}->{Name} eq $curstate){
   				$self->{option_results}->{instancecount}->{$curstate}++;
   			}
   		}
   		$self->{option_results}->{instancecount}->{'total'}++;
	}
}

sub run {
    my ($self, %options) = @_;

    my ($msg, $exit_code);
    my $old_status = 'OK';
    
    $self->manage_selection();

    # Send formated data to Centreon
    # Perf data
	$self->{output}->perfdata_add(label => 'total',
                                  value => $self->{option_results}->{instancecount}->{'total'},
                                  );
                                  
    foreach my $curstate (@{$self->{option_results}->{statetab}}){
    	$self->{output}->perfdata_add(label => $curstate,
                                  value => $self->{option_results}->{instancecount}->{$curstate},
                                  );
        # Most critical state
        if ($self->{option_results}->{instancecount}->{$curstate} != '0') {
        	$exit_code = $EC2_instance_states{$curstate};
        	$exit_code = $self->{output}->get_most_critical(status => [ $exit_code, $old_status ]);
        	$old_status = $exit_code;
        }
    }
    
    # Output message
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Total instances: %s", $self->{option_results}->{instancecount}->{'total'})
                                );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Get the state of your EC2 instances (running, stopped, ...)

=over 8

=item B<--state>

(optional) Specific state to query.

=item B<--no-includeallinstances>

(optional) Includes the health status for running instances only.

=item B<--region>

(optional) The region to use (should be configured directly in aws).

=item B<--exclude>

(optional) State to exclude from the query.

=back

=cut
