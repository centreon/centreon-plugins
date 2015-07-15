
package Paws::SES::SetIdentityDkimEnabled {
  use Moose;
  has DkimEnabled => (is => 'ro', isa => 'Bool', required => 1);
  has Identity => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetIdentityDkimEnabled');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::SetIdentityDkimEnabledResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SetIdentityDkimEnabledResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::SetIdentityDkimEnabled - Arguments for method SetIdentityDkimEnabled on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetIdentityDkimEnabled on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method SetIdentityDkimEnabled.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetIdentityDkimEnabled.

As an example:

  $service_obj->SetIdentityDkimEnabled(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DkimEnabled => Bool

  

Sets whether DKIM signing is enabled for an identity. Set to C<true> to
enable DKIM signing for this identity; C<false> to disable it.










=head2 B<REQUIRED> Identity => Str

  

The identity for which DKIM signing should be enabled or disabled.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetIdentityDkimEnabled in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

