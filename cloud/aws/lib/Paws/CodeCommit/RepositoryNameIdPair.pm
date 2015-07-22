package Paws::CodeCommit::RepositoryNameIdPair {
  use Moose;
  has repositoryId => (is => 'ro', isa => 'Str');
  has repositoryName => (is => 'ro', isa => 'Str');
}
1;
