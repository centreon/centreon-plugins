
package Paws::ELB::AddAvailabilityZonesOutput {
  use Moose;
  has AvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::AddAvailabilityZonesOutput

=head1 ATTRIBUTES

=head2 AvailabilityZones => ArrayRef[Str]

  

The updated list of Availability Zones for the load balancer.











=cut

