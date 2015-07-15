
package Paws::EC2::RequestSpotFleetResponse {
  use Moose;
  has SpotFleetRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotFleetRequestId', traits => ['Unwrapped',], required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::RequestSpotFleetResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> SpotFleetRequestId => Str

  

The ID of the Spot fleet request.











=cut

