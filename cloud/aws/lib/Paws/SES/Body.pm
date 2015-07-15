package Paws::SES::Body {
  use Moose;
  has Html => (is => 'ro', isa => 'Paws::SES::Content');
  has Text => (is => 'ro', isa => 'Paws::SES::Content');
}
1;
