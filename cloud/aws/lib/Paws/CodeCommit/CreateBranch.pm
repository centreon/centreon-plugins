
package Paws::CodeCommit::CreateBranch {
  use Moose;
  has branchName => (is => 'ro', isa => 'Str', required => 1);
  has commitId => (is => 'ro', isa => 'Str', required => 1);
  has repositoryName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateBranch');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::CreateBranch - Arguments for method CreateBranch on Paws::CodeCommit

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateBranch on the 
AWS CodeCommit service. Use the attributes of this class
as arguments to method CreateBranch.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateBranch.

As an example:

  $service_obj->CreateBranch(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> branchName => Str

  

The name of the new branch to create.










=head2 B<REQUIRED> commitId => Str

  

The ID of the commit to point the new branch to.

If this commit ID is not specified, the new branch will point to the
commit that is pointed to by the repository's default branch.










=head2 B<REQUIRED> repositoryName => Str

  

The name of the repository in which you want to create the new branch.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateBranch in L<Paws::CodeCommit>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

