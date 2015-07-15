
package Paws::CognitoIdentity::IdentityDescription {
  use Moose;
  has CreationDate => (is => 'ro', isa => 'Str');
  has IdentityId => (is => 'ro', isa => 'Str');
  has LastModifiedDate => (is => 'ro', isa => 'Str');
  has Logins => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::IdentityDescription

=head1 ATTRIBUTES

=head2 CreationDate => Str

  

Date on which the identity was created.









=head2 IdentityId => Str

  

A unique identifier in the format REGION:GUID.









=head2 LastModifiedDate => Str

  

Date on which the identity was last modified.









=head2 Logins => ArrayRef[Str]

  

A set of optional name-value pairs that map provider names to provider
tokens.











=cut

1;