package Paws::CodeDeploy::AutoScalingGroup {
  use Moose;
  has hook => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
}
1;
