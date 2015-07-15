
package Paws::CloudFormation::DescribeStackEventsOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has StackEvents => (is => 'ro', isa => 'ArrayRef[Paws::CloudFormation::StackEvent]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::DescribeStackEventsOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

String that identifies the start of the next list of events, if there
is one.









=head2 StackEvents => ArrayRef[Paws::CloudFormation::StackEvent]

  

A list of C<StackEvents> structures.











=cut

