package Paws::SES::RawMessage {
  use Moose;
  has Data => (is => 'ro', isa => 'Str', required => 1);
}
1;
