package Paws::DeviceFarm::Upload {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has contentType => (is => 'ro', isa => 'Str');
  has created => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
  has metadata => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');
  has type => (is => 'ro', isa => 'Str');
  has url => (is => 'ro', isa => 'Str');
}
1;
