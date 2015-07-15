package Paws::IAM::AccessKeyMetadata {
  use Moose;
  has AccessKeyId => (is => 'ro', isa => 'Str');
  has CreateDate => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
  has UserName => (is => 'ro', isa => 'Str');
}
1;
