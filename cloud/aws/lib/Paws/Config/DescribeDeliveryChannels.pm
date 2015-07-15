
package Paws::Config::DescribeDeliveryChannels {
  use Moose;
  has DeliveryChannelNames => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeDeliveryChannels');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Config::DescribeDeliveryChannelsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Config::DescribeDeliveryChannels - Arguments for method DescribeDeliveryChannels on Paws::Config

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeDeliveryChannels on the 
AWS Config service. Use the attributes of this class
as arguments to method DescribeDeliveryChannels.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeDeliveryChannels.

As an example:

  $service_obj->DescribeDeliveryChannels(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DeliveryChannelNames => ArrayRef[Str]

  

A list of delivery channel names.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeDeliveryChannels in L<Paws::Config>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

