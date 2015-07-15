package Paws::RDS::DBInstanceStatusInfo {
  use Moose;
  has Message => (is => 'ro', isa => 'Str');
  has Normal => (is => 'ro', isa => 'Bool');
  has Status => (is => 'ro', isa => 'Str');
  has StatusType => (is => 'ro', isa => 'Str');
}
1;
