
package Paws::CloudWatch::DescribeAlarmHistory {
  use Moose;
  has AlarmName => (is => 'ro', isa => 'Str');
  has EndDate => (is => 'ro', isa => 'Str');
  has HistoryItemType => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has StartDate => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeAlarmHistory');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatch::DescribeAlarmHistoryOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeAlarmHistoryResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::DescribeAlarmHistory - Arguments for method DescribeAlarmHistory on Paws::CloudWatch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeAlarmHistory on the 
Amazon CloudWatch service. Use the attributes of this class
as arguments to method DescribeAlarmHistory.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeAlarmHistory.

As an example:

  $service_obj->DescribeAlarmHistory(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AlarmName => Str

  

The name of the alarm.










=head2 EndDate => Str

  

The ending date to retrieve alarm history.










=head2 HistoryItemType => Str

  

The type of alarm histories to retrieve.










=head2 MaxRecords => Int

  

The maximum number of alarm history records to retrieve.










=head2 NextToken => Str

  

The token returned by a previous call to indicate that there is more
data available.










=head2 StartDate => Str

  

The starting date to retrieve alarm history.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeAlarmHistory in L<Paws::CloudWatch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

