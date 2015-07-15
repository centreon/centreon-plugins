package Paws::EC2::UserIdGroupPair {
  use Moose;
  has GroupId => (is => 'ro', isa => 'Str', xmlname => 'groupId', traits => ['Unwrapped']);
  has GroupName => (is => 'ro', isa => 'Str', xmlname => 'groupName', traits => ['Unwrapped']);
  has UserId => (is => 'ro', isa => 'Str', xmlname => 'userId', traits => ['Unwrapped']);
}
1;
