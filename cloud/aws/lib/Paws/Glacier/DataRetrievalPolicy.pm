package Paws::Glacier::DataRetrievalPolicy {
  use Moose;
  has Rules => (is => 'ro', isa => 'ArrayRef[Paws::Glacier::DataRetrievalRule]');
}
1;
