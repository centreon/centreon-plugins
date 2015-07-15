
package Paws::CloudHSM::ListHsms {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListHsms');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudHSM::ListHsmsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::ListHsms - Arguments for method ListHsms on Paws::CloudHSM

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListHsms on the 
Amazon CloudHSM service. Use the attributes of this class
as arguments to method ListHsms.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListHsms.

As an example:

  $service_obj->ListHsms(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The I<NextToken> value from a previous call to ListHsms. Pass null if
this is the first call.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListHsms in L<Paws::CloudHSM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

