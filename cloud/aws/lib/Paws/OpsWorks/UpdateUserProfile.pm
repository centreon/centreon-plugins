
package Paws::OpsWorks::UpdateUserProfile {
  use Moose;
  has AllowSelfManagement => (is => 'ro', isa => 'Bool');
  has IamUserArn => (is => 'ro', isa => 'Str', required => 1);
  has SshPublicKey => (is => 'ro', isa => 'Str');
  has SshUsername => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateUserProfile');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::UpdateUserProfile - Arguments for method UpdateUserProfile on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateUserProfile on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method UpdateUserProfile.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateUserProfile.

As an example:

  $service_obj->UpdateUserProfile(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllowSelfManagement => Bool

  

Whether users can specify their own SSH public key through the My
Settings page. For more information, see Managing User Permissions.










=head2 B<REQUIRED> IamUserArn => Str

  

The user IAM ARN.










=head2 SshPublicKey => Str

  

The user's new SSH public key.










=head2 SshUsername => Str

  

The user's SSH user name. The allowable characters are [a-z], [A-Z],
[0-9], '-', and '_'. If the specified name includes other punctuation
marks, AWS OpsWorks removes them. For example, C<my.name> will be
changed to C<myname>. If you do not specify an SSH user name, AWS
OpsWorks generates one from the IAM user name.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateUserProfile in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

