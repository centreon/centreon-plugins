
package Paws::Glacier::ListParts {
  use Moose;
  has accountId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'accountId' , required => 1);
  has limit => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'limit' );
  has marker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'marker' );
  has uploadId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'uploadId' , required => 1);
  has vaultName => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'vaultName' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListParts');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Glacier::ListPartsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListPartsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::ListParts - Arguments for method ListParts on Paws::Glacier

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListParts on the 
Amazon Glacier service. Use the attributes of this class
as arguments to method ListParts.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListParts.

As an example:

  $service_obj->ListParts(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> accountId => Str

  

The C<AccountId> value is the AWS account ID of the account that owns
the vault. You can either specify an AWS account ID or optionally a
single aposC<->apos (hyphen), in which case Amazon Glacier uses the AWS
account ID associated with the credentials used to sign the request. If
you use an account ID, do not include any hyphens (apos-apos) in the
ID.










=head2 limit => Str

  

Specifies the maximum number of parts returned in the response body. If
this value is not specified, the List Parts operation returns up to
1,000 uploads.










=head2 marker => Str

  

An opaque string used for pagination. This value specifies the part at
which the listing of parts should begin. Get the marker value from the
response of a previous List Parts response. You need only include the
marker if you are continuing the pagination of results started in a
previous List Parts request.










=head2 B<REQUIRED> uploadId => Str

  

The upload ID of the multipart upload.










=head2 B<REQUIRED> vaultName => Str

  

The name of the vault.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListParts in L<Paws::Glacier>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

