
package Paws::AutoScaling::DescribeNotificationConfigurationsAnswer {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has NotificationConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::NotificationConfiguration]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeNotificationConfigurationsAnswer

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.









=head2 B<REQUIRED> NotificationConfigurations => ArrayRef[Paws::AutoScaling::NotificationConfiguration]

  

The notification configurations.











=cut

