package Paws::Route53::Change {
  use Moose;
  has Action => (is => 'ro', isa => 'Str', required => 1);
  has ResourceRecordSet => (is => 'ro', isa => 'Paws::Route53::ResourceRecordSet', required => 1);
}
1;
