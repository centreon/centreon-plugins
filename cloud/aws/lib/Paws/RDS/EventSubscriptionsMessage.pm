
package Paws::RDS::EventSubscriptionsMessage {
  use Moose;
  has EventSubscriptionsList => (is => 'ro', isa => 'ArrayRef[Paws::RDS::EventSubscription]', xmlname => 'EventSubscription', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::EventSubscriptionsMessage

=head1 ATTRIBUTES

=head2 EventSubscriptionsList => ArrayRef[Paws::RDS::EventSubscription]

  

A list of EventSubscriptions data types.









=head2 Marker => Str

  

An optional pagination token provided by a previous
DescribeOrderableDBInstanceOptions request. If this parameter is
specified, the response includes only records beyond the marker, up to
the value specified by C<MaxRecords>.











=cut

