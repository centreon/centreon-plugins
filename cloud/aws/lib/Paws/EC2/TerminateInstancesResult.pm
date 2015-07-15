
package Paws::EC2::TerminateInstancesResult {
  use Moose;
  has TerminatingInstances => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceStateChange]', xmlname => 'instancesSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::TerminateInstancesResult

=head1 ATTRIBUTES

=head2 TerminatingInstances => ArrayRef[Paws::EC2::InstanceStateChange]

  

Information about one or more terminated instances.











=cut

