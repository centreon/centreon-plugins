
package Paws::ECS::ListTaskDefinitions {
  use Moose;
  has familyPrefix => (is => 'ro', isa => 'Str');
  has maxResults => (is => 'ro', isa => 'Int');
  has nextToken => (is => 'ro', isa => 'Str');
  has sort => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListTaskDefinitions');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::ListTaskDefinitionsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::ListTaskDefinitions - Arguments for method ListTaskDefinitions on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListTaskDefinitions on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method ListTaskDefinitions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListTaskDefinitions.

As an example:

  $service_obj->ListTaskDefinitions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 familyPrefix => Str

  

The full family name that you want to filter the C<ListTaskDefinitions>
results with. Specifying a C<familyPrefix> will limit the listed task
definitions to task definition revisions that belong to that family.










=head2 maxResults => Int

  

The maximum number of task definition results returned by
C<ListTaskDefinitions> in paginated output. When this parameter is
used, C<ListTaskDefinitions> only returns C<maxResults> results in a
single page along with a C<nextToken> response element. The remaining
results of the initial request can be seen by sending another
C<ListTaskDefinitions> request with the returned C<nextToken> value.
This value can be between 1 and 100. If this parameter is not used,
then C<ListTaskDefinitions> returns up to 100 results and a
C<nextToken> value if applicable.










=head2 nextToken => Str

  

The C<nextToken> value returned from a previous paginated
C<ListTaskDefinitions> request where C<maxResults> was used and the
results exceeded the value of that parameter. Pagination continues from
the end of the previous results that returned the C<nextToken> value.
This value is C<null> when there are no more results to return.










=head2 sort => Str

  

The order in which to sort the results. Valid values are C<ASC> and
C<DESC>. By default (C<ASC>), task definitions are listed
lexicographically by family name and in ascending numerical order by
revision so that the newest task definitions in a family are listed
last. Setting this parameter to C<DESC> reverses the sort order on
family name and revision so that the newest task definitions in a
family are listed first.










=head2 status => Str

  

The task definition status that you want to filter the
C<ListTaskDefinitions> results with. By default, only C<ACTIVE> task
definitions are listed. By setting this parameter to C<INACTIVE>, you
can view task definitions that are C<INACTIVE> as long as an active
task or service still references them. If you paginate the resulting
output, be sure to keep the C<status> value constant in each subsequent
request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListTaskDefinitions in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

