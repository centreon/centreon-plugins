package Paws::CodeCommit::BranchInfo {
  use Moose;
  has branchName => (is => 'ro', isa => 'Str');
  has commitId => (is => 'ro', isa => 'Str');
}
1;
