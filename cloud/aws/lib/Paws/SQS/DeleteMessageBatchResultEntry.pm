package Paws::SQS::DeleteMessageBatchResultEntry {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', required => 1);
}
1;
