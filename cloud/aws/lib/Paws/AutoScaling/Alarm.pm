package Paws::AutoScaling::Alarm {
  use Moose;
  has AlarmARN => (is => 'ro', isa => 'Str');
  has AlarmName => (is => 'ro', isa => 'Str');
}
1;
