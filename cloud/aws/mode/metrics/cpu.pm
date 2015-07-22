################################################################################
# Copyright 2005-2013 MERETHIS
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
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Stephane Duret <sduret@merethis.com>
#
####################################################################################

package cloud::aws::mode::metrics::cpu;

use strict;
use warnings;
use Data::Dumper;

my $EC2_NameSpace = 'AWS/EC2';
my $EC2_MetricName = 'CPUUtilization';

sub load {
    my (%options) = @_;
    
    #push @{$options{request}}, { oid => $oid_fanSpeedSensorEntry, start => $mapping->{fanSpeedSensorName}->{oid}, end => $mapping->{fanSpeedSensorStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    # Getting data from AWS
    my $Instance = Paws->service($self->{option_results}->{service}, region => $self->{option_results}->{region});

    $self->{status_command} = $Instance->GetMetricStatistics('Namespace' => $EC2_NameSpace,
                                                             'Dimensions' => [{'Name' => 'InstanceId', 'Value' => $self->{option_results}->{object}}],
                                                             'MetricName' => $EC2_MetricName,
                                                             'StartTime' => $self->{option_results}->{starttime},
                                                             'EndTime' => $self->{option_results}->{endtime},
                                                             'Statistics' => $self->{option_results}->{statisticstab},
                                                             'Period' => $self->{option_results}->{period},
    														);
   print Dumper($self->{status_command});
   exit;

    # Compute data
#    $self->{option_results}->{instancecount}->{'total'} = '0';
#    foreach my $curstate (@{$self->{option_results}->{statetab}}){
#    	$self->{option_results}->{instancecount}->{$curstate} = '0';
#    }
#   	foreach my $l (@{$self->{status_command}->{InstanceStatuses}}) {
#   		$self->{result}->{instance}->{$l->InstanceId} = $l->InstanceState->Name;
#   		
#   		# long output for each instance
#   		$self->{output}->output_add(long_msg => "'" . $l->InstanceId . "' [state = " . $l->InstanceState->Name . ']');
#   		
#   		foreach my $curstate (@{$self->{option_results}->{statetab}}){
#   			if($l->InstanceState->Name eq $curstate){
#   				$self->{option_results}->{instancecount}->{$curstate}++;
#   			}
#   		}
#   		$self->{option_results}->{instancecount}->{'total'}++;
#	}
}

1;
