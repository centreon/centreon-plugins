
package Paws::Glacier::InitiateMultipartUpload {
  use Moose;
  has accountId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'accountId' , required => 1);
  has archiveDescription => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-archive-description' );
  has partSize => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-part-size' );
  has vaultName => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'vaultName' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'InitiateMultipartUpload');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{accountId}/vaults/{vaultName}/multipart-uploads');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Glacier::InitiateMultipartUploadOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'InitiateMultipartUploadResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::InitiateMultipartUpload - Arguments for method InitiateMultipartUpload on Paws::Glacier

=head1 DESCRIPTION

This class represents the parameters used for calling the method InitiateMultipartUpload on the 
Amazon Glacier service. Use the attributes of this class
as arguments to method InitiateMultipartUpload.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to InitiateMultipartUpload.

As an example:

  $service_obj->InitiateMultipartUpload(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> accountId => Str

  

The C<AccountId> value is the AWS account ID of the account that owns
the vault. You can either specify an AWS account ID or optionally a
single aposC<->apos (hyphen), in which case Amazon Glacier uses the AWS
account ID associated with the credentials used to sign the request. If
you use an account ID, do not include any hyphens (apos-apos) in the
ID.










=head2 archiveDescription => Str

  

The archive description that you are uploading in parts.

The part size must be a megabyte (1024 KB) multiplied by a power of 2,
for example 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8
MB), and so on. The minimum allowable part size is 1 MB, and the
maximum is 4 GB (4096 MB).










=head2 partSize => Str

  

The size of each part except the last, in bytes. The last part can be
smaller than this part size.










=head2 B<REQUIRED> vaultName => Str

  

The name of the vault.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method InitiateMultipartUpload in L<Paws::Glacier>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

