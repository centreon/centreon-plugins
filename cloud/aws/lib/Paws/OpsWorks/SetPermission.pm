
package Paws::OpsWorks::SetPermission {
  use Moose;
  has AllowSsh => (is => 'ro', isa => 'Bool');
  has AllowSudo => (is => 'ro', isa => 'Bool');
  has IamUserArn => (is => 'ro', isa => 'Str', required => 1);
  has Level => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetPermission');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::SetPermission - Arguments for method SetPermission on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetPermission on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method SetPermission.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetPermission.

As an example:

  $service_obj->SetPermission(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllowSsh => Bool

  

The user is allowed to use SSH to communicate with the instance.










=head2 AllowSudo => Bool

  

The user is allowed to use B<sudo> to elevate privileges.










=head2 B<REQUIRED> IamUserArn => Str

  

The user's IAM ARN.










=head2 Level => Str

  

The user's permission level, which must be set to one of the following
strings. You cannot set your own permissions level.

=over

=item * C<deny>

=item * C<show>

=item * C<deploy>

=item * C<manage>

=item * C<iam_only>

=back

For more information on the permissions associated with these levels,
see Managing User Permissions.










=head2 B<REQUIRED> StackId => Str

  

The stack ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetPermission in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

