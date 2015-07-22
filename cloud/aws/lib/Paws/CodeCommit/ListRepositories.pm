
package Paws::CodeCommit::ListRepositories {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has order => (is => 'ro', isa => 'Str');
  has sortBy => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListRepositories');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeCommit::ListRepositoriesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::ListRepositories - Arguments for method ListRepositories on Paws::CodeCommit

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListRepositories on the 
AWS CodeCommit service. Use the attributes of this class
as arguments to method ListRepositories.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListRepositories.

As an example:

  $service_obj->ListRepositories(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 nextToken => Str

  

An enumeration token that allows the operation to batch the results of
the operation. Batch sizes are 1,000 for list repository operations.
When the client sends the token back to AWS CodeCommit, another page of
1,000 records is retrieved.










=head2 order => Str

  

The order in which to sort the results of a list repositories
operation.










=head2 sortBy => Str

  

The criteria used to sort the results of a list repositories operation.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListRepositories in L<Paws::CodeCommit>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

