package Paws::Glacier::PartListElement {
  use Moose;
  has RangeInBytes => (is => 'ro', isa => 'Str');
  has SHA256TreeHash => (is => 'ro', isa => 'Str');
}
1;
