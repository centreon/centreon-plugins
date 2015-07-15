
package Paws::SES::GetIdentityNotificationAttributesResponse {
  use Moose;
  has NotificationAttributes => (is => 'ro', isa => 'Paws::SES::NotificationAttributes', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::GetIdentityNotificationAttributesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> NotificationAttributes => Paws::SES::NotificationAttributes

  

A map of Identity to IdentityNotificationAttributes.











=cut

