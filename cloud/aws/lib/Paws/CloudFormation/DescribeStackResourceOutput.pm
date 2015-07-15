
package Paws::CloudFormation::DescribeStackResourceOutput {
  use Moose;
  has StackResourceDetail => (is => 'ro', isa => 'Paws::CloudFormation::StackResourceDetail');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::DescribeStackResourceOutput

=head1 ATTRIBUTES

=head2 StackResourceDetail => Paws::CloudFormation::StackResourceDetail

  

A C<StackResourceDetail> structure containing the description of the
specified resource in the specified stack.











=cut

