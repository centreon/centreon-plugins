
package Paws::StorageGateway::RetrieveTapeArchive {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str', required => 1);
  has TapeARN => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RetrieveTapeArchive');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::RetrieveTapeArchiveOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::RetrieveTapeArchive - Arguments for method RetrieveTapeArchive on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method RetrieveTapeArchive on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method RetrieveTapeArchive.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RetrieveTapeArchive.

As an example:

  $service_obj->RetrieveTapeArchive(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> GatewayARN => Str

  

The Amazon Resource Name (ARN) of the gateway you want to retrieve the
virtual tape to. Use the ListGateways operation to return a list of
gateways for your account and region.

You retrieve archived virtual tapes to only one gateway and the gateway
must be a gateway-VTL.










=head2 B<REQUIRED> TapeARN => Str

  

The Amazon Resource Name (ARN) of the virtual tape you want to retrieve
from the virtual tape shelf (VTS).












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RetrieveTapeArchive in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

