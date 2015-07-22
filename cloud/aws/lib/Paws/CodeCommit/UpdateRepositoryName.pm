
package Paws::CodeCommit::UpdateRepositoryName {
  use Moose;
  has newName => (is => 'ro', isa => 'Str', required => 1);
  has oldName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateRepositoryName');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit::UpdateRepositoryName - Arguments for method UpdateRepositoryName on Paws::CodeCommit

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateRepositoryName on the 
AWS CodeCommit service. Use the attributes of this class
as arguments to method UpdateRepositoryName.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateRepositoryName.

As an example:

  $service_obj->UpdateRepositoryName(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> newName => Str

  

=head2 B<REQUIRED> oldName => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateRepositoryName in L<Paws::CodeCommit>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

