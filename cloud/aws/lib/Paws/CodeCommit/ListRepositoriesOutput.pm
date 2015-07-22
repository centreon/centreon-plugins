
package Paws::CodeCommit::ListRepositoriesOutput {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has repositories => (is => 'ro', isa => 'ArrayRef[Paws::CodeCommit::RepositoryNameIdPair]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::ListRepositoriesOutput

=head1 ATTRIBUTES

=head2 nextToken => Str

  

An enumeration token that allows the operation to batch the results of
the operation. Batch sizes are 1,000 for list repository operations.
When the client sends the token back to AWS CodeCommit, another page of
1,000 records is retrieved.









=head2 repositories => ArrayRef[Paws::CodeCommit::RepositoryNameIdPair]

  

Lists the repositories called by the list repositories operation.











=cut

1;