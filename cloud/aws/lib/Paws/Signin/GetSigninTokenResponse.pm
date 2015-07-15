
package Paws::Signin::GetSigninTokenResponse {
  use Moose;
  has SigninToken => (is => 'ro', isa => 'Str', required => 1);
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Signin::GetSigninTokenResponse - Response for method GetSigninToken on Paws::Signin

=head1 DESCRIPTION

=head2 SigninToken => Str

The Token for the Sigin API

=head1 SEE ALSO

This class forms part of L<Paws>, and documents parameters for ListAccessKeys in Paws::IAM

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

