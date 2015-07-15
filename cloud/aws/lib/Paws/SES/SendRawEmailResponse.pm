
package Paws::SES::SendRawEmailResponse {
  use Moose;
  has MessageId => (is => 'ro', isa => 'Str', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::SendRawEmailResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> MessageId => Str

  

The unique message identifier returned from the C<SendRawEmail> action.











=cut

