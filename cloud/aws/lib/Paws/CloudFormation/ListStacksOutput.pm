
package Paws::CloudFormation::ListStacksOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has StackSummaries => (is => 'ro', isa => 'ArrayRef[Paws::CloudFormation::StackSummary]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::ListStacksOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

String that identifies the start of the next list of stacks, if there
is one.









=head2 StackSummaries => ArrayRef[Paws::CloudFormation::StackSummary]

  

A list of C<StackSummary> structures containing information about the
specified stacks.











=cut

