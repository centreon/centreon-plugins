package Paws::S3::RoutingRule {
  use Moose;
  has Condition => (is => 'ro', isa => 'Paws::S3::Condition');
  has Redirect => (is => 'ro', isa => 'Paws::S3::Redirect', required => 1);
}
1;
