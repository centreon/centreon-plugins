package Paws::DeviceFarm::ScheduleRunTest {
  use Moose;
  has filter => (is => 'ro', isa => 'Str');
  has parameters => (is => 'ro', isa => 'Paws::DeviceFarm::TestParameters');
  has testPackageArn => (is => 'ro', isa => 'Str');
  has type => (is => 'ro', isa => 'Str', required => 1);
}
1;
