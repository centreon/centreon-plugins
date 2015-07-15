package Paws::Glacier::DataRetrievalRule {
  use Moose;
  has BytesPerHour => (is => 'ro', isa => 'Int');
  has Strategy => (is => 'ro', isa => 'Str');
}
1;
