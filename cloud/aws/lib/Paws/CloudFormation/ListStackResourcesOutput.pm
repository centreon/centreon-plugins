
package Paws::CloudFormation::ListStackResourcesOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has StackResourceSummaries => (is => 'ro', isa => 'ArrayRef[Paws::CloudFormation::StackResourceSummary]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::ListStackResourcesOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

String that identifies the start of the next list of stack resources,
if there is one.









=head2 StackResourceSummaries => ArrayRef[Paws::CloudFormation::StackResourceSummary]

  

A list of C<StackResourceSummary> structures.











=cut

