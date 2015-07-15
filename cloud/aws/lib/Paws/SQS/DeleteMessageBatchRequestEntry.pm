package Paws::SQS::DeleteMessageBatchRequestEntry {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has ReceiptHandle => (is => 'ro', isa => 'Str', required => 1);
}
1;
