package Paws::CodeDeploy::GitHubLocation {
  use Moose;
  has commitId => (is => 'ro', isa => 'Str');
  has repository => (is => 'ro', isa => 'Str');
}
1;
