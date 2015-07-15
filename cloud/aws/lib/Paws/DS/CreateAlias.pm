
package Paws::DS::CreateAlias {
  use Moose;
  has Alias => (is => 'ro', isa => 'Str', required => 1);
  has DirectoryId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateAlias');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DS::CreateAliasResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DS::CreateAlias - Arguments for method CreateAlias on Paws::DS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateAlias on the 
AWS Directory Service service. Use the attributes of this class
as arguments to method CreateAlias.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateAlias.

As an example:

  $service_obj->CreateAlias(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Alias => Str

  

The requested alias.

The alias must be unique amongst all aliases in AWS. This operation
will throw an C<EntityAlreadyExistsException> if this alias already
exists.










=head2 B<REQUIRED> DirectoryId => Str

  

The identifier of the directory to create the alias for.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateAlias in L<Paws::DS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

