
package Paws::IAM::UpdateLoginProfile {
  use Moose;
  has Password => (is => 'ro', isa => 'Str');
  has PasswordResetRequired => (is => 'ro', isa => 'Bool');
  has UserName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateLoginProfile');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UpdateLoginProfile - Arguments for method UpdateLoginProfile on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateLoginProfile on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method UpdateLoginProfile.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateLoginProfile.

As an example:

  $service_obj->UpdateLoginProfile(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Password => Str

  

The new password for the specified user.










=head2 PasswordResetRequired => Bool

  

Require the specified user to set a new password on next sign-in.










=head2 B<REQUIRED> UserName => Str

  

The name of the user whose password you want to update.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateLoginProfile in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

