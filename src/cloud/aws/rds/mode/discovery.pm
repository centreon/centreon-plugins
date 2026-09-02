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

package cloud::aws::rds::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify' => { name => 'prettify' },
        'type:s'   =>
            {
                name         => 'type',
                default      => 'instance',
                regexp_match => '^(?:instance|cluster)$'
            },
        'prettify' => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $db_instances = $options{custom}->discovery(
        service => 'rds',
        command => $self->{option_results}->{type} eq "instance" ?
            'describe-db-instances' : 'describe-db-clusters'
    );

    my $items = $self->{option_results}->{type} eq "instance" ?
        $db_instances->{DBInstances} : $db_instances->{DBClusters};

    foreach my $item (@{$items}) {
        next if (!defined($item->{DbiResourceId}) && !defined($item->{DBClusterIdentifier}));
        my %rds;
        $rds{type} = "rds";

        if($self->{option_results}->{type} eq "instance") {
            $rds{id} = $item->{DbiResourceId};
            $rds{name} = $item->{DBInstanceIdentifier};
            $rds{status} = $item->{DBInstanceStatus};
            $rds{storage_type} = $item->{StorageType};
            $rds{instance_class} = $item->{DBInstanceClass};
            $rds{availability_zone} = $item->{AvailabilityZone};
            $rds{vpc_id} = $item->{DBSubnetGroup}->{VpcId};
            $rds{engine} = $item->{Engine};
            $rds{engine_version} = $item->{EngineVersion};
            $rds{db_name} = $item->{DBName};
            $rds{endpoint_host_zone_id} = $item->{Endpoint}->{HostedZoneId};
            $rds{endpoint_port} = $item->{Endpoint}->{Port};
            $rds{endpoint_address} = $item->{Endpoint}->{Address};
            $rds{tags} = $item->{TagList};
        } else {
            $rds{id} = $item->{DbClusterResourceId};
            $rds{name} = $item->{DBClusterIdentifier};
            $rds{status} = $item->{Status};
            $rds{availability_zones} = $item->{AvailabilityZones};
            $rds{engine} = $item->{Engine};
            $rds{engine_version} = $item->{EngineVersion};
            $rds{endpoint_host_zone_id} = $item->{HostedZoneId};
            $rds{endpoint_port} = $item->{Port};
            $rds{endpoint_address} = $item->{Endpoint};
            $rds{tags} = $item->{TagList};
            $rds{members} = $item->{DBClusterMembers};
        }
        push @disco_data, \%rds;
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

    return @disco_data if (defined($options{discover}));

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

RDS discovery.

=over 8

=item B<--type>

Set the instance type. Default: C<instance> (can be: 'cluster', 'instance').

=item B<--prettify>

Prettify JSON output.

=back

=cut
