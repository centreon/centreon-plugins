
package Paws::StorageGateway::AddCache {
  use Moose;
  has DiskIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has GatewayARN => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddCache');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::AddCacheOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::AddCache - Arguments for method AddCache on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddCache on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method AddCache.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddCache.

As an example:

  $service_obj->AddCache(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DiskIds => ArrayRef[Str]

  

=head2 B<REQUIRED> GatewayARN => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddCache in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

