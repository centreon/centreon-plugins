
package Paws::CloudFormation::DescribeStacksOutput {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has Stacks => (is => 'ro', isa => 'ArrayRef[Paws::CloudFormation::Stack]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::DescribeStacksOutput

=head1 ATTRIBUTES

=head2 NextToken => Str

  

String that identifies the start of the next list of stacks, if there
is one.









=head2 Stacks => ArrayRef[Paws::CloudFormation::Stack]

  

A list of stack structures.











=cut

