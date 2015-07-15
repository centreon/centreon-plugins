
package Paws::EC2::DeleteFlowLogsResult {
  use Moose;
  has Unsuccessful => (is => 'ro', isa => 'ArrayRef[Paws::EC2::UnsuccessfulItem]', xmlname => 'unsuccessful', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DeleteFlowLogsResult

=head1 ATTRIBUTES

=head2 Unsuccessful => ArrayRef[Paws::EC2::UnsuccessfulItem]

  

Information about the flow logs that could not be deleted successfully.











=cut

