
package Paws::IAM::UploadServerCertificate {
  use Moose;
  has CertificateBody => (is => 'ro', isa => 'Str', required => 1);
  has CertificateChain => (is => 'ro', isa => 'Str');
  has Path => (is => 'ro', isa => 'Str');
  has PrivateKey => (is => 'ro', isa => 'Str', required => 1);
  has ServerCertificateName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UploadServerCertificate');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::UploadServerCertificateResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UploadServerCertificateResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UploadServerCertificate - Arguments for method UploadServerCertificate on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UploadServerCertificate on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method UploadServerCertificate.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UploadServerCertificate.

As an example:

  $service_obj->UploadServerCertificate(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CertificateBody => Str

  

The contents of the public key certificate in PEM-encoded format.










=head2 CertificateChain => Str

  

The contents of the certificate chain. This is typically a
concatenation of the PEM-encoded public key certificates of the chain.










=head2 Path => Str

  

The path for the server certificate. For more information about paths,
see IAM Identifiers in the I<Using IAM> guide.

This parameter is optional. If it is not included, it defaults to a
slash (/).

If you are uploading a server certificate specifically for use with
Amazon CloudFront distributions, you must specify a path using the
C<--path> option. The path must begin with C</cloudfront> and must
include a trailing slash (for example, C</cloudfront/test/>).










=head2 B<REQUIRED> PrivateKey => Str

  

The contents of the private key in PEM-encoded format.










=head2 B<REQUIRED> ServerCertificateName => Str

  

The name for the server certificate. Do not include the path in this
value. The name of the certificate cannot contain any spaces.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UploadServerCertificate in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

