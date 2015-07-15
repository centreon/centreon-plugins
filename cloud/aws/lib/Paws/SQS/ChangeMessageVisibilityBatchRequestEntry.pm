package Paws::SQS::ChangeMessageVisibilityBatchRequestEntry {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has ReceiptHandle => (is => 'ro', isa => 'Str', required => 1);
  has VisibilityTimeout => (is => 'ro', isa => 'Int');
}
1;
