#
# Copyright 2021 Centreon (http://www.centreon.com/)
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
        "service:s@"    => { name => 'service' },
        "prettify"      => { name => 'prettify' },
    });

    $self->{services} = {
        VPC => $self->can('discover_vpc'),
        EC2 => $self->can('discover_ec2'),
        RDS => $self->can('discover_rds'),
        ELB => $self->can('discover_elb'),
        VPN => $self->can('discover_vpn'),
        KINESIS => $self->can('discover_kinesis_stream'),
        DYNAMODB => $self->can('discover_dynamodb_table'),
        APIGATEWAY => $self->can('discover_api'),
        S3 => $self->can('discover_s3_bucket')
    };
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{service}) || $self->{option_results}->{service} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --service option.");
        $self->{output}->option_exit();
    }
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

sub discover_ec2 {
    my (%options) = @_;

    my @disco_data;
    my %asgs;

    my $instances = $options{custom}->discovery(region => $options{region},
        service => 'ec2', command => 'describe-instances');
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
            push @disco_data, \%ec2;
            push @disco_data, \%asg if (defined($asg{name}) && $asg{name} ne '');
        }
    }
    return @disco_data;
}

sub discover_rds {
    my (%options) = @_;
    
    my @disco_data;

    my $db_instances = $options{custom}->discovery(region => $options{region},
        service => 'rds', command => 'describe-db-instances');
    foreach my $db_instance (@{$db_instances->{DBInstances}}) {
        next if (!defined($db_instance->{DbiResourceId}));
        my %rds;
        $rds{type} = "rds";
        $rds{id} = $db_instance->{DbiResourceId};
        $rds{name} = $db_instance->{DBInstanceIdentifier};
        $rds{status} = $db_instance->{DBInstanceStatus};
        $rds{storage_type} = $db_instance->{StorageType};
        $rds{instance_class} = $db_instance->{DBInstanceClass};
        $rds{availability_zone} = $db_instance->{AvailabilityZone};
        $rds{vpc_id} = $db_instance->{DBSubnetGroup}->{VpcId};
        push @disco_data, \%rds;
    }
    return @disco_data;
}

sub discover_elb {
    my (%options) = @_;

    my @disco_data;

    my $load_balancers = $options{custom}->discovery(region => $options{region},
        service => 'elb', command => 'describe-load-balancers');
    foreach my $load_balancer (@{$load_balancers->{LoadBalancerDescriptions}}) {
        next if (!defined($load_balancer->{LoadBalancerName}));
        my %elb;
        $elb{type} = "elb";
        $elb{name} = $load_balancer->{LoadBalancerName};
        $elb{dns_name} = $load_balancer->{DNSName};
        $elb{availability_zones} = $load_balancer->{AvailabilityZones};
        $elb{vpc_id} = $load_balancer->{VPCId};
        push @disco_data, \%elb;
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

sub discover_kinesis_stream {
    my (%options) = @_;

    my @disco_data;

    my $streams = $options{custom}->discovery(region => $options{region},
        service => 'kinesis', command => 'list-streams');
    
    foreach my $stream (@{$streams->{StreamNames}}) {
        my %stream;
        $stream{type} = "kinesis_stream";
        $stream{name} = $stream;
        push @disco_data, \%stream;
    }

    return @disco_data;
}

sub discover_s3_bucket {
    my (%options) = @_;

    my @disco_data;

    my $buckets = $options{custom}->discovery(region => $options{region},
        service => 's3api', command => 'list-buckets');
    
    foreach my $bucket (@{$buckets->{Buckets}}) {
        my %bucket;
        $bucket{type} = "s3_bucket";
        $bucket{name} = $bucket->{Name};
        $bucket{creation_date} = $bucket->{CreationDate};
        push @disco_data, \%bucket;
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

sub discover_api {
    my (%options) = @_;

    my @disco_data;

    my $apis = $options{custom}->discovery(region => $options{region},
        service => 'apigateway', command => 'get-rest-apis');

    foreach my $api (@{$apis->{items}}) {
        my %api;
        $api{id} = $api->{id};
        $api{name} = $api->{name};
        $api{description} = $api->{description};
        $api{version} = $api->{version};
        foreach my $type (@{$api->{endpointConfiguration}->{types}}) {
            push @{$api{types}}, $type;
        }

        push @disco_data, \%api;
    }

    return @disco_data;
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    foreach my $service (@{$self->{option_results}->{service}}) {
        push @disco_data, $self->{services}->{uc($service)}->(custom => $options{custom},
            region => $self->{option_results}->{region}) if (defined($self->{services}->{uc($service)}));
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
