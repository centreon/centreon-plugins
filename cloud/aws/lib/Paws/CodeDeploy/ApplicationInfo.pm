package Paws::CodeDeploy::ApplicationInfo {
  use Moose;
  has applicationId => (is => 'ro', isa => 'Str');
  has applicationName => (is => 'ro', isa => 'Str');
  has createTime => (is => 'ro', isa => 'Str');
  has linkedToGitHub => (is => 'ro', isa => 'Bool');
}
1;
