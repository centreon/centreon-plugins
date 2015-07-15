
package Paws::EC2::CreateSecurityGroupResult {
  use Moose;
  has GroupId => (is => 'ro', isa => 'Str', xmlname => 'groupId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateSecurityGroupResult

=head1 ATTRIBUTES

=head2 GroupId => Str

  

The ID of the security group.











=cut

