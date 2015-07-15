
package Paws::OpsWorks::DescribeElasticIpsResult {
  use Moose;
  has ElasticIps => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::ElasticIp]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeElasticIpsResult

=head1 ATTRIBUTES

=head2 ElasticIps => ArrayRef[Paws::OpsWorks::ElasticIp]

  

An C<ElasticIps> object that describes the specified Elastic IP
addresses.











=cut

1;