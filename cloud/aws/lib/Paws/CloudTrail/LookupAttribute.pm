package Paws::CloudTrail::LookupAttribute {
  use Moose;
  has AttributeKey => (is => 'ro', isa => 'Str', required => 1);
  has AttributeValue => (is => 'ro', isa => 'Str', required => 1);
}
1;
