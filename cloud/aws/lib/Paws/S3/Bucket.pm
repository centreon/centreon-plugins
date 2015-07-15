package Paws::S3::Bucket {
  use Moose;
  has CreationDate => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
}
1;
