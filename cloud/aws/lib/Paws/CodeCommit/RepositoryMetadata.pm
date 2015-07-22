package Paws::CodeCommit::RepositoryMetadata {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has accountId => (is => 'ro', isa => 'Str');
  has cloneUrlHttp => (is => 'ro', isa => 'Str');
  has cloneUrlSsh => (is => 'ro', isa => 'Str');
  has creationDate => (is => 'ro', isa => 'Str');
  has defaultBranch => (is => 'ro', isa => 'Str');
  has lastModifiedDate => (is => 'ro', isa => 'Str');
  has repositoryDescription => (is => 'ro', isa => 'Str');
  has repositoryId => (is => 'ro', isa => 'Str');
  has repositoryName => (is => 'ro', isa => 'Str');
}
1;
