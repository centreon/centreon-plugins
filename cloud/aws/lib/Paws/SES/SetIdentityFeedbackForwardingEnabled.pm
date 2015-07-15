
package Paws::SES::SetIdentityFeedbackForwardingEnabled {
  use Moose;
  has ForwardingEnabled => (is => 'ro', isa => 'Bool', required => 1);
  has Identity => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetIdentityFeedbackForwardingEnabled');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::SetIdentityFeedbackForwardingEnabledResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SetIdentityFeedbackForwardingEnabledResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::SetIdentityFeedbackForwardingEnabled - Arguments for method SetIdentityFeedbackForwardingEnabled on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetIdentityFeedbackForwardingEnabled on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method SetIdentityFeedbackForwardingEnabled.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetIdentityFeedbackForwardingEnabled.

As an example:

  $service_obj->SetIdentityFeedbackForwardingEnabled(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ForwardingEnabled => Bool

  

Sets whether Amazon SES will forward bounce and complaint notifications
as email. C<true> specifies that Amazon SES will forward bounce and
complaint notifications as email, in addition to any Amazon SNS topic
publishing otherwise specified. C<false> specifies that Amazon SES will
publish bounce and complaint notifications only through Amazon SNS.
This value can only be set to C<false> when Amazon SNS topics are set
for both C<Bounce> and C<Complaint> notification types.










=head2 B<REQUIRED> Identity => Str

  

The identity for which to set bounce and complaint notification
forwarding. Examples: C<user@example.com>, C<example.com>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetIdentityFeedbackForwardingEnabled in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

