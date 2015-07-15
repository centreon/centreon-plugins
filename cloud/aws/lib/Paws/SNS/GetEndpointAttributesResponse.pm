
package Paws::SNS::GetEndpointAttributesResponse {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SNS::MapStringToString');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::GetEndpointAttributesResponse

=head1 ATTRIBUTES

=head2 Attributes => Paws::SNS::MapStringToString

  

Attributes include the following:

=over

=item * C<CustomUserData> -- arbitrary user data to associate with the
endpoint. Amazon SNS does not use this data. The data must be in UTF-8
format and less than 2KB.

=item * C<Enabled> -- flag that enables/disables delivery to the
endpoint. Amazon SNS will set this to false when a notification service
indicates to Amazon SNS that the endpoint is invalid. Users can set it
back to true, typically after updating Token.

=item * C<Token> -- device token, also referred to as a registration
id, for an app and mobile device. This is returned from the
notification service when an app and mobile device are registered with
the notification service.

=back











=cut

