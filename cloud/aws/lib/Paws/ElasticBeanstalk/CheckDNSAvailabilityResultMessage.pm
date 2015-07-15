
package Paws::ElasticBeanstalk::CheckDNSAvailabilityResultMessage {
  use Moose;
  has Available => (is => 'ro', isa => 'Bool');
  has FullyQualifiedCNAME => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::CheckDNSAvailabilityResultMessage

=head1 ATTRIBUTES

=head2 Available => Bool

  

Indicates if the specified CNAME is available:

C<true> : The CNAME is available.

C<true> : The CNAME is not available.

=over

=item * C<true> : The CNAME is available.

=item * C<false> : The CNAME is not available.

=back









=head2 FullyQualifiedCNAME => Str

  

The fully qualified CNAME to reserve when CreateEnvironment is called
with the provided prefix.











=cut

