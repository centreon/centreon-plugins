
package Paws::CloudSearch::DescribeAvailabilityOptionsResponse {
  use Moose;
  has AvailabilityOptions => (is => 'ro', isa => 'Paws::CloudSearch::AvailabilityOptionsStatus');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeAvailabilityOptionsResponse

=head1 ATTRIBUTES

=head2 AvailabilityOptions => Paws::CloudSearch::AvailabilityOptionsStatus

  

The availability options configured for the domain. Indicates whether
Multi-AZ is enabled for the domain.











=cut

