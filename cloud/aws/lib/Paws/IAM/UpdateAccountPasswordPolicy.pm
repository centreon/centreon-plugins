
package Paws::IAM::UpdateAccountPasswordPolicy {
  use Moose;
  has AllowUsersToChangePassword => (is => 'ro', isa => 'Bool');
  has HardExpiry => (is => 'ro', isa => 'Bool');
  has MaxPasswordAge => (is => 'ro', isa => 'Int');
  has MinimumPasswordLength => (is => 'ro', isa => 'Int');
  has PasswordReusePrevention => (is => 'ro', isa => 'Int');
  has RequireLowercaseCharacters => (is => 'ro', isa => 'Bool');
  has RequireNumbers => (is => 'ro', isa => 'Bool');
  has RequireSymbols => (is => 'ro', isa => 'Bool');
  has RequireUppercaseCharacters => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateAccountPasswordPolicy');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UpdateAccountPasswordPolicy - Arguments for method UpdateAccountPasswordPolicy on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateAccountPasswordPolicy on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method UpdateAccountPasswordPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateAccountPasswordPolicy.

As an example:

  $service_obj->UpdateAccountPasswordPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllowUsersToChangePassword => Bool

  

Allows all IAM users in your account to use the AWS Management Console
to change their own passwords. For more information, see Letting IAM
Users Change Their Own Passwords in the I<Using IAM> guide.

Default value: false










=head2 HardExpiry => Bool

  

Prevents IAM users from setting a new password after their password has
expired.

Default value: false










=head2 MaxPasswordAge => Int

  

The number of days that an IAM user password is valid. The default
value of 0 means IAM user passwords never expire.

Default value: 0










=head2 MinimumPasswordLength => Int

  

The minimum number of characters allowed in an IAM user password.

Default value: 6










=head2 PasswordReusePrevention => Int

  

Specifies the number of previous passwords that IAM users are prevented
from reusing. The default value of 0 means IAM users are not prevented
from reusing previous passwords.

Default value: 0










=head2 RequireLowercaseCharacters => Bool

  

Specifies whether IAM user passwords must contain at least one
lowercase character from the ISO basic Latin alphabet (a to z).

Default value: false










=head2 RequireNumbers => Bool

  

Specifies whether IAM user passwords must contain at least one numeric
character (0 to 9).

Default value: false










=head2 RequireSymbols => Bool

  

Specifies whether IAM user passwords must contain at least one of the
following non-alphanumeric characters:

! @ 

Default value: false










=head2 RequireUppercaseCharacters => Bool

  

Specifies whether IAM user passwords must contain at least one
uppercase character from the ISO basic Latin alphabet (A to Z).

Default value: false












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateAccountPasswordPolicy in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

