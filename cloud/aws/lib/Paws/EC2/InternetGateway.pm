package Paws::EC2::InternetGateway {
  use Moose;
  has Attachments => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InternetGatewayAttachment]', xmlname => 'attachmentSet', traits => ['Unwrapped']);
  has InternetGatewayId => (is => 'ro', isa => 'Str', xmlname => 'internetGatewayId', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
}
1;
