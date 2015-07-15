package Paws::Route53::HealthCheckConfig {
  use Moose;
  has FailureThreshold => (is => 'ro', isa => 'Int');
  has FullyQualifiedDomainName => (is => 'ro', isa => 'Str');
  has IPAddress => (is => 'ro', isa => 'Str');
  has Port => (is => 'ro', isa => 'Int');
  has RequestInterval => (is => 'ro', isa => 'Int');
  has ResourcePath => (is => 'ro', isa => 'Str');
  has SearchString => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str', required => 1);
}
1;
