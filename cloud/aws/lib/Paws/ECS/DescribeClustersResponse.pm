
package Paws::ECS::DescribeClustersResponse {
  use Moose;
  has clusters => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Cluster]');
  has failures => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Failure]');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DescribeClustersResponse

=head1 ATTRIBUTES

=head2 clusters => ArrayRef[Paws::ECS::Cluster]

  

The list of clusters.









=head2 failures => ArrayRef[Paws::ECS::Failure]

  


=cut

1;