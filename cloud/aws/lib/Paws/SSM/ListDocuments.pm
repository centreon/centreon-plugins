
package Paws::SSM::ListDocuments {
  use Moose;
  has DocumentFilterList => (is => 'ro', isa => 'ArrayRef[Paws::SSM::DocumentFilter]');
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListDocuments');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SSM::ListDocumentsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SSM::ListDocuments - Arguments for method ListDocuments on Paws::SSM

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListDocuments on the 
Amazon Simple Systems Management Service service. Use the attributes of this class
as arguments to method ListDocuments.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListDocuments.

As an example:

  $service_obj->ListDocuments(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DocumentFilterList => ArrayRef[Paws::SSM::DocumentFilter]

  

One or more filters. Use a filter to return a more specific list of
results.










=head2 MaxResults => Int

  

The maximum number of items to return for this call. The call also
returns a token that you can specify in a subsequent call to get the
next set of results.










=head2 NextToken => Str

  

The token for the next set of items to return. (You received this token
from a previous call.)












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListDocuments in L<Paws::SSM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

