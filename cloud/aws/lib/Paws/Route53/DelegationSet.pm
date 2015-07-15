package Paws::Route53::DelegationSet {
  use Moose;
  has CallerReference => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str');
  has NameServers => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
}
1;
