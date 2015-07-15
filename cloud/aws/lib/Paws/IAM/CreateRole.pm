
package Paws::IAM::CreateRole {
  use Moose;
  has AssumeRolePolicyDocument => (is => 'ro', isa => 'Str', required => 1);
  has Path => (is => 'ro', isa => 'Str');
  has RoleName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateRole');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::CreateRoleResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateRoleResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::CreateRole - Arguments for method CreateRole on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateRole on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method CreateRole.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateRole.

As an example:

  $service_obj->CreateRole(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AssumeRolePolicyDocument => Str

  

The policy that grants an entity permission to assume the role.










=head2 Path => Str

  

The path to the role. For more information about paths, see IAM
Identifiers in the I<Using IAM> guide.

This parameter is optional. If it is not included, it defaults to a
slash (/).










=head2 B<REQUIRED> RoleName => Str

  

The name of the role to create.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateRole in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

