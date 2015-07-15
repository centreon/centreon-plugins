package Paws::S3::Owner {
  use Moose;
  has DisplayName => (is => 'ro', isa => 'Str');
  has ID => (is => 'ro', isa => 'Str');
}
1;
