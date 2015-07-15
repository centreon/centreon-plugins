
package Paws::EC2::DescribeFlowLogs {
  use Moose;
  has Filter => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]');
  has FlowLogIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'FlowLogId' );
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeFlowLogs');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeFlowLogsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeFlowLogs - Arguments for method DescribeFlowLogs on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeFlowLogs on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeFlowLogs.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeFlowLogs.

As an example:

  $service_obj->DescribeFlowLogs(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Filter => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<deliver-log-status> - The status of the logs delivery (C<SUCCESS> |
C<FAILED>).

=item *

C<flow-log-id> - The ID of the flow log.

=item *

C<log-group-name> - The name of the log group.

=item *

C<resource-id> - The ID of the VPC, subnet, or network interface.

=item *

C<traffic-type> - The type of traffic (C<ACCEPT> | C<REJECT> | C<ALL>)

=back










=head2 FlowLogIds => ArrayRef[Str]

  

One or more flow log IDs.










=head2 MaxResults => Int

  

The maximum number of results to return for the request in a single
page. The remaining results can be seen by sending another request with
the returned C<NextToken> value. This value can be between 5 and 1000;
if C<MaxResults> is given a value larger than 1000, only 1000 results
are returned. You cannot specify this parameter and the flow log IDs
parameter in the same request.










=head2 NextToken => Str

  

The token to retrieve the next page of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeFlowLogs in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

