
package Paws::ImportExport::GetShippingLabel {
  use Moose;
  has APIVersion => (is => 'ro', isa => 'Str');
  has city => (is => 'ro', isa => 'Str');
  has company => (is => 'ro', isa => 'Str');
  has country => (is => 'ro', isa => 'Str');
  has jobIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has name => (is => 'ro', isa => 'Str');
  has phoneNumber => (is => 'ro', isa => 'Str');
  has postalCode => (is => 'ro', isa => 'Str');
  has stateOrProvince => (is => 'ro', isa => 'Str');
  has street1 => (is => 'ro', isa => 'Str');
  has street2 => (is => 'ro', isa => 'Str');
  has street3 => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetShippingLabel');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ImportExport::GetShippingLabelOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetShippingLabelResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ImportExport::GetShippingLabel - Arguments for method GetShippingLabel on Paws::ImportExport

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetShippingLabel on the 
AWS Import/Export service. Use the attributes of this class
as arguments to method GetShippingLabel.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetShippingLabel.

As an example:

  $service_obj->GetShippingLabel(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 APIVersion => Str

  

=head2 city => Str

  

=head2 company => Str

  

=head2 country => Str

  

=head2 B<REQUIRED> jobIds => ArrayRef[Str]

  

=head2 name => Str

  

=head2 phoneNumber => Str

  

=head2 postalCode => Str

  

=head2 stateOrProvince => Str

  

=head2 street1 => Str

  

=head2 street2 => Str

  

=head2 street3 => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetShippingLabel in L<Paws::ImportExport>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

