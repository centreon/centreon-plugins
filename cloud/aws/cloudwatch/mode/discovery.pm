#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package cloud::aws::cloudwatch::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "service:s"    => { name => 'service' },
        "prettify"      => { name => 'prettify' },
    });

    $self->{services} = {
        APIGATEWAY         => $self->can('discover_api'),
        BACKUP_VAULT       => $self->can('discover_backup_vault'),
        # DYNAMODB         => $self->can('discover_dynamodb_table'),
        EBS                => $self->can('discover_ebs'),
        EC2                => $self->can('discover_ec2'),
        EFS                => $self->can('discover_efs'),
        ELB_APP            => $self->can('discover_elb_app'),
        ELB_CLASSIC        => $self->can('discover_elb_classic'),
        ELB_NETWORK        => $self->can('discover_elb_network'),
        FSX                => $self->can('discover_fsx'),
        KINESIS            => $self->can('discover_kinesis_stream'),
        LAMBDA             => $self->can('discover_lambda'),
        RDS                => $self->can('discover_rds'),
        S3_BUCKET          => $self->can('discover_s3_bucket'),
        SNS                => $self->can('discover_sns'),
        SPOT_FLEET_REQUEST => $self->can('discover_spotfleetrequest'),
        SQS                => $self->can('discover_sqs'),
        # VPC              => $self->can('discover_vpc'),
        # VPN              => $self->can('discover_vpn')
    };
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # if (!defined($self->{option_results}->{service}) || $self->{option_results}->{service} eq '') {
    #     $self->{output}->add_option_msg(short_msg => "Need to specify --service option.");
    #     $self->{output}->option_exit();
    # }
}

sub discover_vpc {
    my (%options) = @_;
    
    my @disco_data;

    my $vpcs = $options{custom}->discovery(region => $options{region},
        service => 'ec2', command => 'describe-vpcs');
    foreach my $vpc (@{$vpcs->{Vpcs}}) {
        next if (!defined($vpc->{VpcId}));
        my %vpc;
        $vpc{type} = "vpc";
        $vpc{id} = $vpc->{VpcId};
        $vpc{state} = $vpc->{State};
        $vpc{cidr} = $vpc->{CidrBlock};
        foreach my $tag (@{$vpc->{Tags}}) {
            if ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                $vpc{name} = $tag->{Value};
            }
            push @{$vpc{tags}}, { key => $tag->{Key}, value => $tag->{Value} };
        }
        push @disco_data, \%vpc;
    }
    return @disco_data;
}

sub discover_vpn {
    my (%options) = @_;

    my @disco_data;

    my $vpns = $options{custom}->discovery(region => $options{region},
        service => 'ec2', command => 'describe-vpn-connections');
    foreach my $connection (@{$vpns->{VpnConnections}}) {
        next if (!defined($connection->{VpnConnectionId}));
        my %vpn;
        $vpn{type} = "vpn";
        $vpn{id} = $connection->{VpnConnectionId};
        $vpn{connection_type} = $connection->{Type};
        $vpn{state} = $connection->{State};
        $vpn{category} = $connection->{Category};
        foreach my $tag (@{$connection->{Tags}}) {
            if ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                $vpn{name} = $tag->{Value};
            }
            push @{$vpn{tags}}, { key => $tag->{Key}, value => $tag->{Value} };
        }
        push @disco_data, \%vpn;
    }
    return @disco_data;
}

sub discover_dynamodb_table {
    my (%options) = @_;

    my @disco_data;

    my $tables = $options{custom}->discovery(region => $options{region},
        service => 'dynamodb', command => 'list-tables');
    
    foreach my $table (@{$tables->{TableNames}}) {
        my %table;
        $table{type} = "dynamodb_table";
        $table{name} = $table;
        push @disco_data, \%table;
    }

    return @disco_data;
}

sub discover_ec2 {
    my (%options) = @_;
    
    my @disco_data;
    my %asgs;
    my $instances = $options{custom}->discovery(
        service => 'ec2',
        command => 'describe-instances'
    );

    foreach my $reservation (@{$instances->{Reservations}}) {
        foreach my $instance (@{$reservation->{Instances}}) {
            next if (!defined($instance->{InstanceId}));            
            my %asg;
            $asg{type} = "asg";
            my %ec2;
            $ec2{type} = "ec2";
            $ec2{id} = $instance->{InstanceId};
            $ec2{state} = $instance->{State}->{Name};
            $ec2{key_name} = $instance->{KeyName};
            $ec2{private_ip} = $instance->{PrivateIpAddress};
            $ec2{private_dns_name} = $instance->{PrivateDnsName};
            $ec2{public_dns_name} = $instance->{PublicDnsName};
            $ec2{instance_type} = $instance->{InstanceType};
            $ec2{vpc_id} = $instance->{VpcId};
            foreach my $tag (@{$instance->{Tags}}) {
                if ($tag->{Key} eq "aws:autoscaling:groupName" && defined($tag->{Value})) {
                    $ec2{asg} = $tag->{Value};
                    next if (defined($asgs{$tag->{Value}}));
                    $asg{name} = $tag->{Value};
                    $asgs{$tag->{Value}} = 1;
                }
                if ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                    $ec2{name} = $tag->{Value};
                }
                push @{$ec2{tags}}, { key => $tag->{Key}, value => $tag->{Value} };
            }
            push @disco_data, \%ec2;#unless (defined($self->{option_results}->{filter_type})
                # && $ec2{type} !~ /$self->{option_results}->{filter_type}/);
            push @disco_data, \%asg;# unless ((defined($self->{option_results}->{filter_type})
                # && $asg{type} !~ /$self->{option_results}->{filter_type}/) || !defined($asg{name}) || $asg{name} eq '');
        }
    }

    return @disco_data;

}

sub discover_spotfleetrequest {
    my (%options) = @_;
    
    my @disco_data;
    my $spot_fleet_requests = $options{custom}->discovery(
        service => 'ec2',
        command => 'describe-spot-fleet-requests'
    );

    foreach my $fleet_request (@{$spot_fleet_requests->{SpotFleetRequestConfigs}}) {
        my %sfr;
        $sfr{state} = $fleet_request->{SpotFleetRequestState};
        $sfr{id} = $fleet_request->{SpotFleetRequestId};
        $sfr{activity_status} = $fleet_request->{ActivityStatus};
        $sfr{type} = 'spot_fleet_request';

        push @disco_data, \%sfr;# unless (defined($self->{option_results}->{filter_state})
            # && $sfr{state} !~ /$self->{option_results}->{filter_state}/);
    }

    return @disco_data;
}

sub discover_api {
    my (%options) = @_;

    use cloud::aws::apigateway::mode::discovery;
    my @disco_data = cloud::aws::apigateway::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_backup_vault {
    my (%options) = @_;

    use cloud::aws::backup::mode::discovery;
    my @disco_data = cloud::aws::backup::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_ebs {
    my (%options) = @_;

    use cloud::aws::ebs::mode::discovery;
    my @disco_data = cloud::aws::ebs::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

# sub discover_ec2 {
#     my (%options) = @_;

#     use cloud::aws::ec2::mode::discovery;
#     my @disco_data = cloud::aws::ec2::mode::discovery->run(custom => $options{custom}, discover => 1);
#     return @disco_data;
# }

sub discover_efs {
    my (%options) = @_;

    use cloud::aws::efs::mode::discovery;
    my @disco_data = cloud::aws::efs::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_elbv2_app {
    my (%options) = @_;

    use cloud::aws::elb::application::mode::discovery;
    my @disco_data = cloud::aws::elb::application::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_elb_classic {
    my (%options) = @_;

    use cloud::aws::elb::classic::mode::discovery;
    my @disco_data = cloud::aws::elb::classic::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_elb_network {
    my (%options) = @_;

    use cloud::aws::elb::network::mode::discovery;
    my @disco_data = cloud::aws::elb::network::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}


sub discover_fsx {
    my (%options) = @_;

    use cloud::aws::fsx::mode::discovery;
    my @disco_data = cloud::aws::fsx::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_kinesis_stream {
    my (%options) = @_;

    use cloud::aws::kinesis::mode::discovery;
    my @disco_data = cloud::aws::kinesis::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_lambda {
    my (%options) = @_;

    use cloud::aws::lambda::mode::discovery;
    my @disco_data = cloud::aws::lambda::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_rds {
    my (%options) = @_;

    use cloud::aws::rds::mode::discovery;
    my @disco_data = cloud::aws::rds::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

sub discover_s3_bucket {
    my (%options) = @_;

    use cloud::aws::s3::mode::discovery;
    my @disco_data = cloud::aws::s3::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;  
}

sub discover_sns {
    my (%options) = @_;

    use cloud::aws::sns::mode::discovery;
    my @disco_data = cloud::aws::sns::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}

# sub discover_spotfleetrequest {
#     my (%options) = @_;

#     use cloud::aws::ec2::mode::discoveryspotfleetrequests;
#     my @disco_data = cloud::aws::ec2::mode::discoveryspotfleetrequests->run(custom => $options{custom}, discover => 1);
#     return @disco_data;
# }

sub discover_sqs {
    my (%options) = @_;

    use cloud::aws::sqs::mode::discovery;
    my @disco_data = cloud::aws::sqs::mode::discovery->run(custom => $options{custom}, discover => 1);
    return @disco_data;
}



sub run {
    my ($self, %options) = @_;
use Data::Dumper;
    my @disco_data_ori;
    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my @uncommon_keys = ("dns_name", "engine", "id", "lifecycle", "private_ip", "state");

    foreach my $service (keys %{$self->{services}}) {
    # foreach my $service (split(',', $self->{option_results}->{service})) {
        # push @disco_data, $self->{services}->{uc($service)}->(custom => $options{custom},
        #     region => $self->{option_results}->{region}) if (defined($self->{services}->{uc($service)}));
        @disco_data_ori = $self->{services}->{$service}->(custom => $options{custom},
                          region => $self->{option_results}->{region}) if (defined($self->{services}->{$service}));;

        foreach (@disco_data_ori){
            $_->{resource_type} = lc($service);
            
            foreach my $key (@uncommon_keys) {
                if (!defined($_->{$key})) {
                    $_->{$key} = "undefined";
                }
            }
        }
  
        push @disco_data, @disco_data_ori;
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--service>

Choose the service from which discover
resources (Can be: 'VPC', 'EC2', 'RDS',
'ELB', 'VPN') (Mandatory).

=item B<--prettify>

Prettify JSON output.

=back

=cut
