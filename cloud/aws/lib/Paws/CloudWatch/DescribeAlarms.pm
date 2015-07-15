
package Paws::CloudWatch::DescribeAlarms {
  use Moose;
  has ActionPrefix => (is => 'ro', isa => 'Str');
  has AlarmNamePrefix => (is => 'ro', isa => 'Str');
  has AlarmNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has StateValue => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeAlarms');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatch::DescribeAlarmsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeAlarmsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::DescribeAlarms - Arguments for method DescribeAlarms on Paws::CloudWatch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeAlarms on the 
Amazon CloudWatch service. Use the attributes of this class
as arguments to method DescribeAlarms.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeAlarms.

As an example:

  $service_obj->DescribeAlarms(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ActionPrefix => Str

  

The action name prefix.










=head2 AlarmNamePrefix => Str

  

The alarm name prefix. C<AlarmNames> cannot be specified if this
parameter is specified.










=head2 AlarmNames => ArrayRef[Str]

  

A list of alarm names to retrieve information for.










=head2 MaxRecords => Int

  

The maximum number of alarm descriptions to retrieve.










=head2 NextToken => Str

  

The token returned by a previous call to indicate that there is more
data available.










=head2 StateValue => Str

  

The state value to be used in matching alarms.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeAlarms in L<Paws::CloudWatch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

