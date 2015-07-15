package Paws::SQS::AttributeMap {
  use Moose;
  with 'Paws::API::MapParser';

  use MooseX::ClassAttribute;
  class_has xml_keys =>(is => 'ro', default => 'Name');
  class_has xml_values =>(is => 'ro', default => 'Value');

  has ApproximateFirstReceiveTimestamp => (is => 'ro', isa => 'Str');
  has ApproximateReceiveCount => (is => 'ro', isa => 'Str');
  has SenderId => (is => 'ro', isa => 'Str');
  has SentTimestamp => (is => 'ro', isa => 'Str');
}
1
