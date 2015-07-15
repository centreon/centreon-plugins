
package Paws::SES::VerifyDomainDkimResponse {
  use Moose;
  has DkimTokens => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::VerifyDomainDkimResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> DkimTokens => ArrayRef[Str]

  

A set of character strings that represent the domain's identity. If the
identity is an email address, the tokens represent the domain of that
address.

Using these tokens, you will need to create DNS CNAME records that
point to DKIM public keys hosted by Amazon SES. Amazon Web Services
will eventually detect that you have updated your DNS records; this
detection process may take up to 72 hours. Upon successful detection,
Amazon SES will be able to DKIM-sign emails originating from that
domain.

For more information about creating DNS records using DKIM tokens, go
to the Amazon SES Developer Guide.











=cut

