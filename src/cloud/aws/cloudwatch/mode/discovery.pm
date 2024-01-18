#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
        "prettify"      => { name => 'prettify' }
    });

    $self->{services} = {
        APIGATEWAY         => $self->can('discover_api'),
        BACKUP_VAULT       => $self->can('discover_backup_vault'),
#        DYNAMODB           => $self->can('discover_dynamodb_table'),
        CLOUDFRONT         => $self->can('discover_cloudfront'),
        ELASTICACHE        => $self->can('discover_elasticache'),
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
#        VPC                => $self->can('discover_vpc'),
        VPN                => $self->can('discover_vpn')
    };

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub discover_vpc {
    my (%options) = @_;

    my @disco_data;

    my $vpcs = $options{custom}->discovery(
        region => $options{region},
        service => 'ec2',
        command => 'describe-vpcs'
    );
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
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
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
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_api {
    my (%options) = @_;

    use cloud::aws::apigateway::mode::discovery;
    my @disco_data = cloud::aws::apigateway::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_backup_vault {
    my (%options) = @_;

    use cloud::aws::backup::mode::discovery;
    my @disco_data = cloud::aws::backup::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_cloudfront {
    my (%options) = @_;

    use cloud::aws::cloudfront::mode::discovery;
    my @disco_data = cloud::aws::cloudfront::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_elasticache {
    my (%options) = @_;

    use cloud::aws::elasticache::mode::discovery;
    my @disco_data = cloud::aws::elasticache::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_ebs {
    my (%options) = @_;

    use cloud::aws::ebs::mode::discovery;
    my @disco_data = cloud::aws::ebs::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_ec2 {
    my (%options) = @_;

    use cloud::aws::ec2::mode::discovery;
    my @disco_data = cloud::aws::ec2::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_efs {
    my (%options) = @_;

    use cloud::aws::efs::mode::discovery;
    my @disco_data = cloud::aws::efs::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_elb_app {
    my (%options) = @_;

    use cloud::aws::elb::application::mode::discovery;
    my @disco_data = cloud::aws::elb::application::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_elb_classic {
    my (%options) = @_;

    use cloud::aws::elb::classic::mode::discovery;
    my @disco_data = cloud::aws::elb::classic::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_elb_network {
    my (%options) = @_;

    use cloud::aws::elb::network::mode::discovery;
    my @disco_data = cloud::aws::elb::network::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_fsx {
    my (%options) = @_;

    use cloud::aws::fsx::mode::discovery;
    my @disco_data = cloud::aws::fsx::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_kinesis_stream {
    my (%options) = @_;

    use cloud::aws::kinesis::mode::discovery;
    my @disco_data = cloud::aws::kinesis::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_lambda {
    my (%options) = @_;

    use cloud::aws::lambda::mode::discovery;
    my @disco_data = cloud::aws::lambda::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_rds {
    my (%options) = @_;

    use cloud::aws::rds::mode::discovery;
    my @disco_data = cloud::aws::rds::mode::discovery->run(custom => $options{custom}, discover => 1);
    next if (\@disco_data == 0);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_s3_bucket {
    my (%options) = @_;

    use cloud::aws::s3::mode::discovery;
    my @disco_data = cloud::aws::s3::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_sns {
    my (%options) = @_;

    use cloud::aws::sns::mode::discovery;
    my @disco_data = cloud::aws::sns::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_spotfleetrequest {
    my (%options) = @_;

    use cloud::aws::ec2::mode::discoveryspotfleetrequests;
    my @disco_data = cloud::aws::ec2::mode::discoveryspotfleetrequests->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_sqs {
    my (%options) = @_;

    use cloud::aws::sqs::mode::discovery;
    my @disco_data = cloud::aws::sqs::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub discover_vpn {
    my (%options) = @_;

    use cloud::aws::vpn::mode::discovery;
    my @disco_data = cloud::aws::vpn::mode::discovery->run(custom => $options{custom}, discover => 1);
    my @disco_keys = keys %{$disco_data[0]} if (@disco_data != 0);
    return \@disco_data, \@disco_keys;
}

sub run {
    my ($self, %options) = @_;

    my $disco_data_ori;
    my $disco_data_keys;
    my @disco_data;
    my $disco_stats;

    my %asset_attr_keys;

    $disco_stats->{start_time} = time();

    foreach my $service (keys %{$self->{services}}) {
        ($disco_data_ori, $disco_data_keys) = $self->{services}->{$service}->(custom => $options{custom});
        $asset_attr_keys{$_}++ for (@{$disco_data_keys});
        push @disco_data, @{$disco_data_ori} if @{$disco_data_ori};
    }

    foreach my $discovered_item (@disco_data) {
        foreach my $key (keys %asset_attr_keys) {
            if (!defined($discovered_item->{$key})) {
                $discovered_item->{$key} = "NOT_APPLICABLE";
            }
        }
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

=item B<--prettify>

Prettify JSON output.

=back

=cut
