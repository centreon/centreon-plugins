package Paws::OpsWorks::EnvironmentVariable {
  use Moose;
  has Key => (is => 'ro', isa => 'Str', required => 1);
  has Secure => (is => 'ro', isa => 'Bool');
  has Value => (is => 'ro', isa => 'Str', required => 1);
}
1;
