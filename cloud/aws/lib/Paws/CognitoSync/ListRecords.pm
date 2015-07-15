
package Paws::CognitoSync::ListRecords {
  use Moose;
  has DatasetName => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'DatasetName' , required => 1);
  has IdentityId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'IdentityId' , required => 1);
  has IdentityPoolId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'IdentityPoolId' , required => 1);
  has LastSyncCount => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'lastSyncCount' );
  has MaxResults => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'maxResults' );
  has NextToken => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'nextToken' );
  has SyncSessionToken => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'syncSessionToken' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListRecords');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/records');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoSync::ListRecordsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListRecordsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::ListRecords - Arguments for method ListRecords on Paws::CognitoSync

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListRecords on the 
Amazon Cognito Sync service. Use the attributes of this class
as arguments to method ListRecords.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListRecords.

As an example:

  $service_obj->ListRecords(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DatasetName => Str

  

A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9,
'_' (underscore), '-' (dash), and '.' (dot).










=head2 B<REQUIRED> IdentityId => Str

  

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito. GUID generation is unique within a region.










=head2 B<REQUIRED> IdentityPoolId => Str

  

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito. GUID generation is unique within a region.










=head2 LastSyncCount => Int

  

The last server sync count for this record.










=head2 MaxResults => Int

  

The maximum number of results to be returned.










=head2 NextToken => Str

  

A pagination token for obtaining the next page of results.










=head2 SyncSessionToken => Str

  

A token containing a session ID, identity ID, and expiration.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListRecords in L<Paws::CognitoSync>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

