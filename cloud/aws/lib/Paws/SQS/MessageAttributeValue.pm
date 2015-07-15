package Paws::SQS::MessageAttributeValue {
  use Moose;
  has BinaryListValues => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'BinaryListValue', request_name => 'BinaryListValue', traits => ['Unwrapped','NameInRequest']);
  has BinaryValue => (is => 'ro', isa => 'Str');
  has DataType => (is => 'ro', isa => 'Str', required => 1);
  has StringListValues => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'StringListValue', request_name => 'StringListValue', traits => ['Unwrapped','NameInRequest']);
  has StringValue => (is => 'ro', isa => 'Str');
}
1;
