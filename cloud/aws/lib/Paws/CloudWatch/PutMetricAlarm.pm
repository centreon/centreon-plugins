
package Paws::CloudWatch::PutMetricAlarm {
  use Moose;
  has ActionsEnabled => (is => 'ro', isa => 'Bool');
  has AlarmActions => (is => 'ro', isa => 'ArrayRef[Str]');
  has AlarmDescription => (is => 'ro', isa => 'Str');
  has AlarmName => (is => 'ro', isa => 'Str', required => 1);
  has ComparisonOperator => (is => 'ro', isa => 'Str', required => 1);
  has Dimensions => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatch::Dimension]');
  has EvaluationPeriods => (is => 'ro', isa => 'Int', required => 1);
  has InsufficientDataActions => (is => 'ro', isa => 'ArrayRef[Str]');
  has MetricName => (is => 'ro', isa => 'Str', required => 1);
  has Namespace => (is => 'ro', isa => 'Str', required => 1);
  has OKActions => (is => 'ro', isa => 'ArrayRef[Str]');
  has Period => (is => 'ro', isa => 'Int', required => 1);
  has Statistic => (is => 'ro', isa => 'Str', required => 1);
  has Threshold => (is => 'ro', isa => 'Num', required => 1);
  has Unit => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutMetricAlarm');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::PutMetricAlarm - Arguments for method PutMetricAlarm on Paws::CloudWatch

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutMetricAlarm on the 
Amazon CloudWatch service. Use the attributes of this class
as arguments to method PutMetricAlarm.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutMetricAlarm.

As an example:

  $service_obj->PutMetricAlarm(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ActionsEnabled => Bool

  

Indicates whether or not actions should be executed during any changes
to the alarm's state.










=head2 AlarmActions => ArrayRef[Str]

  

The list of actions to execute when this alarm transitions into an
C<ALARM> state from any other state. Each action is specified as an
Amazon Resource Number (ARN). Currently the only action supported is
publishing to an Amazon SNS topic or an Amazon Auto Scaling policy.










=head2 AlarmDescription => Str

  

The description for the alarm.










=head2 B<REQUIRED> AlarmName => Str

  

The descriptive name for the alarm. This name must be unique within the
user's AWS account










=head2 B<REQUIRED> ComparisonOperator => Str

  

The arithmetic operation to use when comparing the specified
C<Statistic> and C<Threshold>. The specified C<Statistic> value is used
as the first operand.










=head2 Dimensions => ArrayRef[Paws::CloudWatch::Dimension]

  

The dimensions for the alarm's associated metric.










=head2 B<REQUIRED> EvaluationPeriods => Int

  

The number of periods over which data is compared to the specified
threshold.










=head2 InsufficientDataActions => ArrayRef[Str]

  

The list of actions to execute when this alarm transitions into an
C<INSUFFICIENT_DATA> state from any other state. Each action is
specified as an Amazon Resource Number (ARN). Currently the only action
supported is publishing to an Amazon SNS topic or an Amazon Auto
Scaling policy.










=head2 B<REQUIRED> MetricName => Str

  

The name for the alarm's associated metric.










=head2 B<REQUIRED> Namespace => Str

  

The namespace for the alarm's associated metric.










=head2 OKActions => ArrayRef[Str]

  

The list of actions to execute when this alarm transitions into an
C<OK> state from any other state. Each action is specified as an Amazon
Resource Number (ARN). Currently the only action supported is
publishing to an Amazon SNS topic or an Amazon Auto Scaling policy.










=head2 B<REQUIRED> Period => Int

  

The period in seconds over which the specified statistic is applied.










=head2 B<REQUIRED> Statistic => Str

  

The statistic to apply to the alarm's associated metric.










=head2 B<REQUIRED> Threshold => Num

  

The value against which the specified statistic is compared.










=head2 Unit => Str

  

The unit for the alarm's associated metric.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutMetricAlarm in L<Paws::CloudWatch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

