
package Paws::OpsWorks::DescribeStacksResult {
  use Moose;
  has Stacks => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::Stack]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeStacksResult

=head1 ATTRIBUTES

=head2 Stacks => ArrayRef[Paws::OpsWorks::Stack]

  

An array of C<Stack> objects that describe the stacks.











=cut

1;