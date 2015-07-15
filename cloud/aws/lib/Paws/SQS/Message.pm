package Paws::SQS::Message {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SQS::AttributeMap', xmlname => 'Attribute', request_name => 'Attribute', traits => ['Unwrapped','NameInRequest']);
  has Body => (is => 'ro', isa => 'Str');
  has MD5OfBody => (is => 'ro', isa => 'Str');
  has MD5OfMessageAttributes => (is => 'ro', isa => 'Str');
  has MessageAttributes => (is => 'ro', isa => 'Paws::SQS::MessageAttributeMap', xmlname => 'MessageAttribute', request_name => 'MessageAttribute', traits => ['Unwrapped','NameInRequest']);
  has MessageId => (is => 'ro', isa => 'Str');
  has ReceiptHandle => (is => 'ro', isa => 'Str');
}
1;
