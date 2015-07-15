package Paws::SNS::PlatformApplication {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SNS::MapStringToString');
  has PlatformApplicationArn => (is => 'ro', isa => 'Str');
}
1;
