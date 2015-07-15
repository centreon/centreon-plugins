
package Paws::EC2::DeleteVpcEndpointsResult {
  use Moose;
  has Unsuccessful => (is => 'ro', isa => 'ArrayRef[Paws::EC2::UnsuccessfulItem]', xmlname => 'unsuccessful', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DeleteVpcEndpointsResult

=head1 ATTRIBUTES

=head2 Unsuccessful => ArrayRef[Paws::EC2::UnsuccessfulItem]

  

Information about the endpoints that were not successfully deleted.











=cut

