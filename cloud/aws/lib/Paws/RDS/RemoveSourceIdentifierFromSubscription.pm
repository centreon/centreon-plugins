
package Paws::RDS::RemoveSourceIdentifierFromSubscription {
  use Moose;
  has SourceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has SubscriptionName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemoveSourceIdentifierFromSubscription');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::RemoveSourceIdentifierFromSubscriptionResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RemoveSourceIdentifierFromSubscriptionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::RemoveSourceIdentifierFromSubscription - Arguments for method RemoveSourceIdentifierFromSubscription on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemoveSourceIdentifierFromSubscription on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method RemoveSourceIdentifierFromSubscription.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemoveSourceIdentifierFromSubscription.

As an example:

  $service_obj->RemoveSourceIdentifierFromSubscription(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> SourceIdentifier => Str

  

The source identifier to be removed from the subscription, such as the
B<DB instance identifier> for a DB instance or the name of a security
group.










=head2 B<REQUIRED> SubscriptionName => Str

  

The name of the RDS event notification subscription you want to remove
a source identifier from.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemoveSourceIdentifierFromSubscription in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

