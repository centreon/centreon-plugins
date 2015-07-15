
package Paws::EC2::CreateFlowLogsResult {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str', xmlname => 'clientToken', traits => ['Unwrapped',]);
  has FlowLogIds => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'flowLogIdSet', traits => ['Unwrapped',]);
  has Unsuccessful => (is => 'ro', isa => 'ArrayRef[Paws::EC2::UnsuccessfulItem]', xmlname => 'unsuccessful', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateFlowLogsResult

=head1 ATTRIBUTES

=head2 ClientToken => Str

  

Unique, case-sensitive identifier you provide to ensure the idempotency
of the request.









=head2 FlowLogIds => ArrayRef[Str]

  

The IDs of the flow logs.









=head2 Unsuccessful => ArrayRef[Paws::EC2::UnsuccessfulItem]

  

Information about the flow logs that could not be created successfully.











=cut

