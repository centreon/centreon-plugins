
package Paws::Signin::Login {
  use Moose;
  has Issuer => (is => 'ro', isa => 'Str', required => 1);
  has Destination => (is => 'ro', isa => 'Str', required => 1);
  has SigninToken => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'login');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Signin::LoginResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Signin::GetSigninToken - Arguments for method GetSigninToken on Paws::Signin

=head1 DESCRIPTION

=head2 Session => Str

A JSON encoded string that represents an object with keys sessionId, sessionKey and sessionToken
with the temporary credentials for the session. 

=head1 SEE ALSO

This class forms part of L<Paws>, and documents parameters for ListAccessKeys in Paws::IAM

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

