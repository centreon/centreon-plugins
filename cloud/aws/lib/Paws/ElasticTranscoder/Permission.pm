package Paws::ElasticTranscoder::Permission {
  use Moose;
  has Access => (is => 'ro', isa => 'ArrayRef[Str]');
  has Grantee => (is => 'ro', isa => 'Str');
  has GranteeType => (is => 'ro', isa => 'Str');
}
1;
