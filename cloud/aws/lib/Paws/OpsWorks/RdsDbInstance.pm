package Paws::OpsWorks::RdsDbInstance {
  use Moose;
  has Address => (is => 'ro', isa => 'Str');
  has DbInstanceIdentifier => (is => 'ro', isa => 'Str');
  has DbPassword => (is => 'ro', isa => 'Str');
  has DbUser => (is => 'ro', isa => 'Str');
  has Engine => (is => 'ro', isa => 'Str');
  has MissingOnRds => (is => 'ro', isa => 'Bool');
  has RdsDbInstanceArn => (is => 'ro', isa => 'Str');
  has Region => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str');
}
1;
