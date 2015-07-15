package Paws::Route53::ResourceRecord {
  use Moose;
  has Value => (is => 'ro', isa => 'Str', required => 1);
}
1;
