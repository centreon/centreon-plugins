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

package cloud::aws::mode::cloudwatch;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Data::Dumper;
use POSIX;
use Switch;
use JSON;

my $EC2_statistics = 'Average Minimum Maximum Sum SampleCount';
my $EC2_service = 'CloudWatch';
my $def_endtime = time();

my $EC2_cpu = {'NameSpace' => 'AWS/EC2',
			   'MetricName' => 'CPUUtilization',
			   'ObjectName' => 'InstanceId',
               };
			   
sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.2';

    $options{options}->add_options(arguments =>
                                {
                                  "metric:s"        => { name => 'metric' },
                                  "region:s"      => { name => 'region' },
                                  "period:s"      => { name => 'period', default => '300' },
                                  "starttime:s"      => { name => 'starttime' },
                                  "endtime:s"      => { name => 'endtime' },
                                  "statistics:s"  => { name => 'statistics', default => 'all' },
                                  "exclude-statistics:s"  => { name => 'exclude-statistics' },
                                  "object:s"      => { name => 'object' },
                                  "warning:s"     => { name => 'warning' },
                                  "critical:s"     => { name => 'critical' },
                                });
    $self->{result} = {};
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
    
    if (!defined($self->{option_results}->{region})) {
        $self->{output}->add_option_msg(severity => 'UNKNOWN',
	       								short_msg => "Please set the region. ex: --region \"eu-west-1\"");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{metric})) {
        $self->{output}->add_option_msg(severity => 'UNKNOWN',
	       								short_msg => "Please give a metric to watch (cpu, disk, ...).");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{object})) {
        $self->{output}->add_option_msg(severity => 'UNKNOWN',
	       								short_msg => "Please give the object to request (instanceid, ...).");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{endtime})) {
        $self->{option_results}->{endtime} = strftime("%FT%H:%M:%S.000Z", gmtime($def_endtime));
    }
    
    if (!defined($self->{option_results}->{starttime})) {
        $self->{option_results}->{starttime} = strftime("%FT%H:%M:%S.000Z", gmtime($def_endtime - 600));
    }
    switch ($self->{option_results}->{metric}) {
			case 'cpu' { $self->{metric} = $EC2_cpu }
			else { print "previous case not true" }
		}
}

sub manage_selection {
    my ($self, %options) = @_;
    my @result;

	# Getting some parameters
	# statistics
	if ($self->{option_results}->{statistics} eq 'all'){
		$self->{option_results}->{statistics} = $EC2_statistics;
    }
    else {
    	@{$self->{option_results}->{statisticstab}} = split(/,/, $self->{option_results}->{statistics});
    	foreach my $curstate (@{$self->{option_results}->{statisticstab}}) {
    		if (! grep { /^$curstate$/ } split(/ /, $EC2_statistics) ) {
	       		$self->{output}->add_option_msg(severity => 'UNKNOWN',
	       										short_msg => "The state $curstate doesn't exist.");
        		$self->{output}->option_exit();
	    	}
    	}
    	$self->{option_results}->{statistics} =~ s/,/ /g ;
    }
    
    # exclusions
#    if (defined($self->{option_results}->{'exclude-statistics'})){
#    	my @excludetab = split(/,/, $self->{option_results}->{'exclude-statistics'});
#		my %array1 = map { $_ => 1 } @excludetab;
#		@{$self->{option_results}->{statisticstab}} = grep { not $array1{$_} } @{$self->{option_results}->{statisticstab}};
#    }
	
	# Getting data from AWS
    # Build command
    my $awscommand = "aws cloudwatch get-metric-statistics ";
    if ($self->{option_results}->{region}) {
    	$awscommand = $awscommand . "--region " . $self->{option_results}->{region} . " ";
    }
    $awscommand = $awscommand . "--namespace " . $self->{metric}->{NameSpace} . " ";
    $awscommand = $awscommand . "--metric-name " . $self->{metric}->{MetricName} . " ";
    $awscommand = $awscommand . "--start-time " . $self->{option_results}->{starttime} . " ";
    $awscommand = $awscommand . "--end-time " . $self->{option_results}->{endtime} . " ";
    $awscommand = $awscommand . "--period " . $self->{option_results}->{period} . " ";
    $awscommand = $awscommand . "--statistics " . $self->{option_results}->{statistics} . " ";
    $awscommand = $awscommand . "--dimensions Name=$self->{metric}->{ObjectName},Value=$self->{option_results}->{object}";
    
    # Exec command
    my $jsoncontent = `$awscommand`;
    my $json = JSON->new;
    eval {
        $self->{command_return} = $json->decode($jsoncontent);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json answer");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
#    my $datas = {};
    
    my ($msg, $exit_code);
    my $old_status = 'OK';
    
    $self->manage_selection();

    $self->{output}->output_add(long_msg => sprintf("CPU Usage is %.2f%%", $self->{command_return}->{Datapoints}[0]->{Average}));

    $exit_code = $self->{perfdata}->threshold_check(value => $self->{command_return}->{Datapoints}[0]->{Average}, 
                            threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("CPU usage is: %.2f%%", $self->{command_return}->{Datapoints}[0]->{Average}));
    $self->{output}->perfdata_add(label => 'cpu', unit => '%',
                                  value => sprintf("%.2f", $self->{command_return}->{Datapoints}[0]->{Average}),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => 100);
                                  
    $self->{output}->display();
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
