
package Paws::SES::ListIdentities {
  use Moose;
  has IdentityType => (is => 'ro', isa => 'Str');
  has MaxItems => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListIdentities');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::ListIdentitiesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListIdentitiesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::ListIdentities - Arguments for method ListIdentities on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListIdentities on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method ListIdentities.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListIdentities.

As an example:

  $service_obj->ListIdentities(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 IdentityType => Str

  

The type of the identities to list. Possible values are "EmailAddress"
and "Domain". If this parameter is omitted, then all identities will be
listed.










=head2 MaxItems => Int

  

The maximum number of identities per page. Possible values are 1-1000
inclusive.










=head2 NextToken => Str

  

The token to use for pagination.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListIdentities in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

