
package Paws::EC2::DescribePrefixLists {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool');
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has PrefixListIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'PrefixListId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribePrefixLists');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribePrefixListsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribePrefixLists - Arguments for method DescribePrefixLists on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribePrefixLists on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribePrefixLists.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribePrefixLists.

As an example:

  $service_obj->DescribePrefixLists(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<prefix-list-id>: The ID of a prefix list.

=item *

C<prefix-list-name>: The name of a prefix list.

=back










=head2 MaxResults => Int

  

The maximum number of items to return for this request. The request
returns a token that you can specify in a subsequent call to get the
next set of results.

Constraint: If the value specified is greater than 1000, we return only
1000 items.










=head2 NextToken => Str

  

The token for the next set of items to return. (You received this token
from a prior call.)










=head2 PrefixListIds => ArrayRef[Str]

  

One or more prefix list IDs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribePrefixLists in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

