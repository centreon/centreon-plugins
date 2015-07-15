
package Paws::DS::CreateComputer {
  use Moose;
  has ComputerAttributes => (is => 'ro', isa => 'ArrayRef[Paws::DS::Attribute]');
  has ComputerName => (is => 'ro', isa => 'Str', required => 1);
  has DirectoryId => (is => 'ro', isa => 'Str', required => 1);
  has OrganizationalUnitDistinguishedName => (is => 'ro', isa => 'Str');
  has Password => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateComputer');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DS::CreateComputerResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DS::CreateComputer - Arguments for method CreateComputer on Paws::DS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateComputer on the 
AWS Directory Service service. Use the attributes of this class
as arguments to method CreateComputer.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateComputer.

As an example:

  $service_obj->CreateComputer(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ComputerAttributes => ArrayRef[Paws::DS::Attribute]

  

An array of Attribute objects that contain any LDAP attributes to apply
to the computer account.










=head2 B<REQUIRED> ComputerName => Str

  

The name of the computer account.










=head2 B<REQUIRED> DirectoryId => Str

  

The identifier of the directory to create the computer account in.










=head2 OrganizationalUnitDistinguishedName => Str

  

The fully-qualified distinguished name of the organizational unit to
place the computer account in.










=head2 B<REQUIRED> Password => Str

  

A one-time password that is used to join the computer to the directory.
You should generate a random, strong password to use for this
parameter.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateComputer in L<Paws::DS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

