package Paws::DeviceFarm::ScheduleRunConfiguration {
  use Moose;
  has auxiliaryApps => (is => 'ro', isa => 'ArrayRef[Str]');
  has extraDataPackageArn => (is => 'ro', isa => 'Str');
  has locale => (is => 'ro', isa => 'Str');
  has location => (is => 'ro', isa => 'Paws::DeviceFarm::Location');
  has networkProfileArn => (is => 'ro', isa => 'Str');
  has radios => (is => 'ro', isa => 'Paws::DeviceFarm::Radios');
}
1;
