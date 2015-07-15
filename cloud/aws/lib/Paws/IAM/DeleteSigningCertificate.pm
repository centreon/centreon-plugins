
package Paws::IAM::DeleteSigningCertificate {
  use Moose;
  has CertificateId => (is => 'ro', isa => 'Str', required => 1);
  has UserName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteSigningCertificate');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::DeleteSigningCertificate - Arguments for method DeleteSigningCertificate on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteSigningCertificate on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method DeleteSigningCertificate.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteSigningCertificate.

As an example:

  $service_obj->DeleteSigningCertificate(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CertificateId => Str

  

The ID of the signing certificate to delete.










=head2 UserName => Str

  

The name of the user the signing certificate belongs to.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteSigningCertificate in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

