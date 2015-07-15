
package Paws::EC2::UnmonitorInstancesResult {
  use Moose;
  has InstanceMonitorings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceMonitoring]', xmlname => 'instancesSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::UnmonitorInstancesResult

=head1 ATTRIBUTES

=head2 InstanceMonitorings => ArrayRef[Paws::EC2::InstanceMonitoring]

  

Monitoring information for one or more instances.











=cut

