
package Paws::RDS::AccountAttributesMessage {
  use Moose;
  has AccountQuotas => (is => 'ro', isa => 'ArrayRef[Paws::RDS::AccountQuota]', xmlname => 'AccountQuota', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::AccountAttributesMessage

=head1 ATTRIBUTES

=head2 AccountQuotas => ArrayRef[Paws::RDS::AccountQuota]

  

A list of AccountQuota objects. Within this list, each quota has a
name, a count of usage toward the quota maximum, and a maximum value
for the quota.











=cut

