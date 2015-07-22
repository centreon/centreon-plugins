
package Paws::CodeCommit::BatchGetRepositoriesOutput {
  use Moose;
  has repositories => (is => 'ro', isa => 'ArrayRef[Paws::CodeCommit::RepositoryMetadata]');
  has repositoriesNotFound => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::BatchGetRepositoriesOutput

=head1 ATTRIBUTES

=head2 repositories => ArrayRef[Paws::CodeCommit::RepositoryMetadata]

  

A list of repositories returned by the batch get repositories
operation.









=head2 repositoriesNotFound => ArrayRef[Str]

  

Returns a list of repository names for which information could not be
found.











=cut

1;