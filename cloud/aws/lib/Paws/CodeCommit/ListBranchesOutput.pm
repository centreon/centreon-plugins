
package Paws::CodeCommit::ListBranchesOutput {
  use Moose;
  has branches => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::ListBranchesOutput

=head1 ATTRIBUTES

=head2 branches => ArrayRef[Str]

  

The list of branch names.









=head2 nextToken => Str

  

An enumeration token that returns the batch of the results.











=cut

1;