package Paws::CodeDeploy::TimeRange {
  use Moose;
  has end => (is => 'ro', isa => 'Str');
  has start => (is => 'ro', isa => 'Str');
}
1;
