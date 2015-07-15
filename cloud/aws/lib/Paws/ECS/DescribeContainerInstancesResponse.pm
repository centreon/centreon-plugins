
package Paws::ECS::DescribeContainerInstancesResponse {
  use Moose;
  has containerInstances => (is => 'ro', isa => 'ArrayRef[Paws::ECS::ContainerInstance]');
  has failures => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Failure]');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DescribeContainerInstancesResponse

=head1 ATTRIBUTES

=head2 containerInstances => ArrayRef[Paws::ECS::ContainerInstance]

  

The list of container instances.









=head2 failures => ArrayRef[Paws::ECS::Failure]

  


=cut

1;