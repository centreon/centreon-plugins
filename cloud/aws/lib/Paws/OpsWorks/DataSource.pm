package Paws::OpsWorks::DataSource {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has DatabaseName => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
}
1;
