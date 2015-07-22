
package Paws::CodeCommit::BatchGetRepositories {
  use Moose;
  has repositoryNames => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'BatchGetRepositories');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeCommit::BatchGetRepositoriesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::BatchGetRepositories - Arguments for method BatchGetRepositories on Paws::CodeCommit

=head1 DESCRIPTION

This class represents the parameters used for calling the method BatchGetRepositories on the 
AWS CodeCommit service. Use the attributes of this class
as arguments to method BatchGetRepositories.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to BatchGetRepositories.

As an example:

  $service_obj->BatchGetRepositories(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> repositoryNames => ArrayRef[Str]

  

The names of the repositories to get information about.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method BatchGetRepositories in L<Paws::CodeCommit>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

