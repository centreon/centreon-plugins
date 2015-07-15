
package Paws::EC2::DescribeFlowLogsResult {
  use Moose;
  has FlowLogs => (is => 'ro', isa => 'ArrayRef[Paws::EC2::FlowLog]', xmlname => 'flowLogSet', traits => ['Unwrapped',]);
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeFlowLogsResult

=head1 ATTRIBUTES

=head2 FlowLogs => ArrayRef[Paws::EC2::FlowLog]

  

Information about the flow logs.









=head2 NextToken => Str

  

The token to use to retrieve the next page of results. This value is
C<null> when there are no more results to return.











=cut

