
package Paws::ELB::RegisterEndPointsOutput {
  use Moose;
  has Instances => (is => 'ro', isa => 'ArrayRef[Paws::ELB::Instance]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::RegisterEndPointsOutput

=head1 ATTRIBUTES

=head2 Instances => ArrayRef[Paws::ELB::Instance]

  

The updated list of instances for the load balancer.











=cut

