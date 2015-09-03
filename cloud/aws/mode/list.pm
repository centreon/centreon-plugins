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

package cloud::aws::mode::list;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use Switch;
use centreon::plugins::misc;
use Data::Dumper;
use JSON;

my $AWSServices = 'EC2,S3,RDS';
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
                                  "service:s"     => { name => 'service', default => $AWSServices },
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
#        $self->{output}->add_option_msg(short_msg => "Please set the region. ex: --region \"eu-west-1\"");
#        $self->{output}->option_exit();
#    }
}

sub manage_selection {
    my ($self, %options) = @_;

    @{$self->{option_results}->{servicetab}} = split(/,/, $self->{option_results}->{service});
    foreach my $service (@{$self->{option_results}->{servicetab}}) {
        $self->{result}->{count}->{$service} = '0';
		switch ($service) {
			case 'EC2' { $self->EC2(); }
			case 'S3' { $self->S3(); }
			case 'RDS' { $self->RDS(); }
			else {
				$self->{output}->add_option_msg(short_msg => "Service $service doesn't exists");
        		$self->{output}->option_exit();
			}
		}
	}
}

sub EC2 {
	my ($self, %options) = @_;
	
	# Build command
    my $awscommand = "aws ec2 describe-instances ";
    if ($self->{option_results}->{region}) {
    	$awscommand = $awscommand . "--region ".$self->{option_results}->{region}." ";
    }
    
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
   	foreach my $instance (@{$self->{command_return}->{Reservations}}) {
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
	my (@buckets,@return) = ();
	
	# Build command
    my $awscommand = "aws s3 ls ";
    if ($self->{option_results}->{region}) {
    	$awscommand = $awscommand . "--region ".$self->{option_results}->{region}." ";
    }
    
    # Exec command
    @return = `$awscommand`;
    foreach my $line (@return) {
    	chomp $line;
    	my ($date, $time, $name) = split(/ /,$line);
    	my $creationdate = $date . " " . $time;
    	push(@buckets,{Name=>$name,CreationDate=>$creationdate});
    }

    # Compute data
   	foreach my $bucket (@buckets) {
   		$self->{result}->{'S3'}->{$bucket->{Name}} = {'Creation date' => $bucket->{CreationDate}};
   		$self->{result}->{count}->{'S3'}++;
	}
}

sub RDS {
	my ($self, %options) = @_;
	
	# Build command
    my $awscommand = "aws rds describe-db-instances ";
    if ($self->{option_results}->{region}) {
    	$awscommand = $awscommand . "--region ".$self->{option_results}->{region}." ";
    }
    
    # Exec command
    my $jsoncontent = `$awscommand`;
    my $json = JSON->new;
    eval {
        $self->{command_return} = $json->decode($jsoncontent);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    
	# Compute data
   	foreach my $dbinstance (@{$self->{command_return}->{DBInstances}}) {
   		$self->{result}->{'RDS'}->{$dbinstance->{DBInstanceIdentifier}} = {'State' => $dbinstance->{DBInstanceStatus}};
   		$self->{result}->{count}->{'RDS'}++;
	}
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();

    # Send formated data to Centreon
    foreach my $service (@{$self->{option_results}->{servicetab}}) {
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

List your EC2, RDS instance and S3 buckets

=over 8

=item B<--service>

(optional) List one particular service.

=item B<--region>

(optional) The region to use (should be configured directly in aws).

=item B<--exclude>

(optional) Service to exclude from the scan.

=back

=cut
