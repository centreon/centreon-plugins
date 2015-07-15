package Paws::ELB::SourceSecurityGroup {
  use Moose;
  has GroupName => (is => 'ro', isa => 'Str');
  has OwnerAlias => (is => 'ro', isa => 'Str');
}
1;
