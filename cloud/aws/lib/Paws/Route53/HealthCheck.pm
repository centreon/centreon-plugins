package Paws::Route53::HealthCheck {
  use Moose;
  has CallerReference => (is => 'ro', isa => 'Str', required => 1);
  has HealthCheckConfig => (is => 'ro', isa => 'Paws::Route53::HealthCheckConfig', required => 1);
  has HealthCheckVersion => (is => 'ro', isa => 'Int', required => 1);
  has Id => (is => 'ro', isa => 'Str', required => 1);
}
1;
