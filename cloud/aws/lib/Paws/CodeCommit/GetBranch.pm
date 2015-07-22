
package Paws::CodeCommit::GetBranch {
  use Moose;
  has branchName => (is => 'ro', isa => 'Str');
  has repositoryName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetBranch');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeCommit::GetBranchOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::GetBranch - Arguments for method GetBranch on Paws::CodeCommit

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetBranch on the 
AWS CodeCommit service. Use the attributes of this class
as arguments to method GetBranch.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetBranch.

As an example:

  $service_obj->GetBranch(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 branchName => Str

  

The name of the branch for which you want to retrieve information.










=head2 repositoryName => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetBranch in L<Paws::CodeCommit>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

