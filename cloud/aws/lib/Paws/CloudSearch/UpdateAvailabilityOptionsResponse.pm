
package Paws::CloudSearch::UpdateAvailabilityOptionsResponse {
  use Moose;
  has AvailabilityOptions => (is => 'ro', isa => 'Paws::CloudSearch::AvailabilityOptionsStatus');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::UpdateAvailabilityOptionsResponse

=head1 ATTRIBUTES

=head2 AvailabilityOptions => Paws::CloudSearch::AvailabilityOptionsStatus

  

The newly-configured availability options. Indicates whether Multi-AZ
is enabled for the domain.











=cut

