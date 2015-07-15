package Paws::S3::RequestPaymentConfiguration {
  use Moose;
  has Payer => (is => 'ro', isa => 'Str', required => 1);
}
1;
