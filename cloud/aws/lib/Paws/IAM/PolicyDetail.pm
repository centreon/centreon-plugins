package Paws::IAM::PolicyDetail {
  use Moose;
  has PolicyDocument => (is => 'ro', isa => 'Str', decode_as => 'URLJSON', method => 'Policy', traits => ['JSONAttribute']);
  has PolicyName => (is => 'ro', isa => 'Str');
}
1;
