package Paws::EC2::CreateVolumePermission {
  use Moose;
  has Group => (is => 'ro', isa => 'Str', xmlname => 'group', traits => ['Unwrapped']);
  has UserId => (is => 'ro', isa => 'Str', xmlname => 'userId', traits => ['Unwrapped']);
}
1;
