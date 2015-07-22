
package Paws::Signin::GetSigninToken {
  use Moose;
  has SessionId => (is => 'ro', isa => 'Str', required => 1);
  has SessionKey => (is => 'ro', isa => 'Str', required => 1);
  has SessionToken => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/federation');
  class_has _api_call => (isa => 'Str', is => 'ro', default => 'getSigninToken');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Signin::GetSigninTokenResponse');
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

