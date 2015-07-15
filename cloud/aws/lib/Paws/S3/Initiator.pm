package Paws::S3::Initiator {
  use Moose;
  has DisplayName => (is => 'ro', isa => 'Str');
  has ID => (is => 'ro', isa => 'Str');
}
1;
