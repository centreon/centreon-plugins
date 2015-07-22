
package Paws::CodeCommit::CreateRepository {
  use Moose;
  has repositoryDescription => (is => 'ro', isa => 'Str');
  has repositoryName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateRepository');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeCommit::CreateRepositoryOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::CreateRepository - Arguments for method CreateRepository on Paws::CodeCommit

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateRepository on the 
AWS CodeCommit service. Use the attributes of this class
as arguments to method CreateRepository.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateRepository.

As an example:

  $service_obj->CreateRepository(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 repositoryDescription => Str

  

A comment or description about the new repository.










=head2 B<REQUIRED> repositoryName => Str

  

The name of the new repository to be created.

The repository name must be unique across the calling AWS account. In
addition, repository names are restricted to alphanumeric characters.
The suffix ".git" is prohibited.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateRepository in L<Paws::CodeCommit>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

