
package Paws::IAM::RemoveRoleFromInstanceProfile {
  use Moose;
  has InstanceProfileName => (is => 'ro', isa => 'Str', required => 1);
  has RoleName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemoveRoleFromInstanceProfile');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::RemoveRoleFromInstanceProfile - Arguments for method RemoveRoleFromInstanceProfile on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemoveRoleFromInstanceProfile on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method RemoveRoleFromInstanceProfile.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemoveRoleFromInstanceProfile.

As an example:

  $service_obj->RemoveRoleFromInstanceProfile(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> InstanceProfileName => Str

  

The name of the instance profile to update.










=head2 B<REQUIRED> RoleName => Str

  

The name of the role to remove.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemoveRoleFromInstanceProfile in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

