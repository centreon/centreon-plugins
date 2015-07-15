
package Paws::CognitoSync::ListIdentityPoolUsage {
  use Moose;
  has MaxResults => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'maxResults' );
  has NextToken => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'nextToken' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListIdentityPoolUsage');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/identitypools');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoSync::ListIdentityPoolUsageResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListIdentityPoolUsageResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::ListIdentityPoolUsage - Arguments for method ListIdentityPoolUsage on Paws::CognitoSync

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListIdentityPoolUsage on the 
Amazon Cognito Sync service. Use the attributes of this class
as arguments to method ListIdentityPoolUsage.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListIdentityPoolUsage.

As an example:

  $service_obj->ListIdentityPoolUsage(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 MaxResults => Int

  

The maximum number of results to be returned.










=head2 NextToken => Str

  

A pagination token for obtaining the next page of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListIdentityPoolUsage in L<Paws::CognitoSync>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

