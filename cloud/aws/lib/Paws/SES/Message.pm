package Paws::SES::Message {
  use Moose;
  has Body => (is => 'ro', isa => 'Paws::SES::Body', required => 1);
  has Subject => (is => 'ro', isa => 'Paws::SES::Content', required => 1);
}
1;
