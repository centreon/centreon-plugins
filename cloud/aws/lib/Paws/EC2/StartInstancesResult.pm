
package Paws::EC2::StartInstancesResult {
  use Moose;
  has StartingInstances => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceStateChange]', xmlname => 'instancesSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::StartInstancesResult

=head1 ATTRIBUTES

=head2 StartingInstances => ArrayRef[Paws::EC2::InstanceStateChange]

  

Information about one or more started instances.











=cut

