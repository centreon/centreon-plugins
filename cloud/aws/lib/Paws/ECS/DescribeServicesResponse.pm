
package Paws::ECS::DescribeServicesResponse {
  use Moose;
  has failures => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Failure]');
  has services => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Service]');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DescribeServicesResponse

=head1 ATTRIBUTES

=head2 failures => ArrayRef[Paws::ECS::Failure]

  

Any failures associated with the call.









=head2 services => ArrayRef[Paws::ECS::Service]

  

The list of services described.











=cut

1;