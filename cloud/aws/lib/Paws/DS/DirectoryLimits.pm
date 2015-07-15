package Paws::DS::DirectoryLimits {
  use Moose;
  has CloudOnlyDirectoriesCurrentCount => (is => 'ro', isa => 'Int');
  has CloudOnlyDirectoriesLimit => (is => 'ro', isa => 'Int');
  has CloudOnlyDirectoriesLimitReached => (is => 'ro', isa => 'Bool');
  has ConnectedDirectoriesCurrentCount => (is => 'ro', isa => 'Int');
  has ConnectedDirectoriesLimit => (is => 'ro', isa => 'Int');
  has ConnectedDirectoriesLimitReached => (is => 'ro', isa => 'Bool');
}
1;
