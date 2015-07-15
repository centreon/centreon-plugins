package Paws::IAM::AccessKeyLastUsed {
  use Moose;
  has LastUsedDate => (is => 'ro', isa => 'Str', required => 1);
  has Region => (is => 'ro', isa => 'Str', required => 1);
  has ServiceName => (is => 'ro', isa => 'Str', required => 1);
}
1;
