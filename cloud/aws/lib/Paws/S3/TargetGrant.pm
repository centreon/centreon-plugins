package Paws::S3::TargetGrant {
  use Moose;
  has Grantee => (is => 'ro', isa => 'Paws::S3::Grantee');
  has Permission => (is => 'ro', isa => 'Str');
}
1;
