package Paws::SQS::SendMessageBatchRequestEntry {
  use Moose;
  has DelaySeconds => (is => 'ro', isa => 'Int');
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has MessageAttributes => (is => 'ro', isa => 'Paws::SQS::MessageAttributeMap', xmlname => 'MessageAttribute', request_name => 'MessageAttribute', traits => ['Unwrapped','NameInRequest']);
  has MessageBody => (is => 'ro', isa => 'Str', required => 1);
}
1;
