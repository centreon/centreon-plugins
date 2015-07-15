package Paws::EMR {
  use Moose;
  sub service { 'elasticmapreduce' }
  sub version { '2009-03-31' }
  sub target_prefix { 'ElasticMapReduce' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub AddInstanceGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::AddInstanceGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddJobFlowSteps {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::AddJobFlowSteps', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::AddTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCluster {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::DescribeCluster', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeJobFlows {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::DescribeJobFlows', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStep {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::DescribeStep', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListBootstrapActions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::ListBootstrapActions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListClusters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::ListClusters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListInstanceGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::ListInstanceGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::ListInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListSteps {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::ListSteps', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyInstanceGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::ModifyInstanceGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::RemoveTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RunJobFlow {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::RunJobFlow', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetTerminationProtection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::SetTerminationProtection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetVisibleToAllUsers {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::SetVisibleToAllUsers', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub TerminateJobFlows {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EMR::TerminateJobFlows', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EMR - Perl Interface to AWS Amazon Elastic MapReduce

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('EMR')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon Elastic MapReduce (Amazon EMR) is a web service that makes it
easy to process large amounts of data efficiently. Amazon EMR uses
Hadoop processing combined with several AWS products to do tasks such
as web indexing, data mining, log file analysis, machine learning,
scientific simulation, and data warehousing.










=head1 METHODS

=head2 AddInstanceGroups(InstanceGroups => ArrayRef[Paws::EMR::InstanceGroupConfig], JobFlowId => Str)

Each argument is described in detail in: L<Paws::EMR::AddInstanceGroups>

Returns: a L<Paws::EMR::AddInstanceGroupsOutput> instance

  

AddInstanceGroups adds an instance group to a running cluster.











=head2 AddJobFlowSteps(JobFlowId => Str, Steps => ArrayRef[Paws::EMR::StepConfig])

Each argument is described in detail in: L<Paws::EMR::AddJobFlowSteps>

Returns: a L<Paws::EMR::AddJobFlowStepsOutput> instance

  

AddJobFlowSteps adds new steps to a running job flow. A maximum of 256
steps are allowed in each job flow.

If your job flow is long-running (such as a Hive data warehouse) or
complex, you may require more than 256 steps to process your data. You
can bypass the 256-step limitation in various ways, including using the
SSH shell to connect to the master node and submitting queries directly
to the software running on the master node, such as Hive and Hadoop.
For more information on how to do this, go to Add More than 256 Steps
to a Job Flow in the I<Amazon Elastic MapReduce Developer's Guide>.

A step specifies the location of a JAR file stored either on the master
node of the job flow or in Amazon S3. Each step is performed by the
main function of the main class of the JAR file. The main class can be
specified either in the manifest of the JAR or by using the
MainFunction parameter of the step.

Elastic MapReduce executes each step in the order listed. For a step to
be considered complete, the main function must exit with a zero exit
code and all Hadoop jobs started while the step was running must have
completed and run successfully.

You can only add steps to a job flow that is in one of the following
states: STARTING, BOOTSTRAPPING, RUNNING, or WAITING.











=head2 AddTags(ResourceId => Str, Tags => ArrayRef[Paws::EMR::Tag])

Each argument is described in detail in: L<Paws::EMR::AddTags>

Returns: a L<Paws::EMR::AddTagsOutput> instance

  

Adds tags to an Amazon EMR resource. Tags make it easier to associate
clusters in various ways, such as grouping clusters to track your
Amazon EMR resource allocation costs. For more information, see Tagging
Amazon EMR Resources.











=head2 DescribeCluster(ClusterId => Str)

Each argument is described in detail in: L<Paws::EMR::DescribeCluster>

Returns: a L<Paws::EMR::DescribeClusterOutput> instance

  

Provides cluster-level details including status, hardware and software
configuration, VPC settings, and so on. For information about the
cluster steps, see ListSteps.











=head2 DescribeJobFlows([CreatedAfter => Str, CreatedBefore => Str, JobFlowIds => ArrayRef[Str], JobFlowStates => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EMR::DescribeJobFlows>

Returns: a L<Paws::EMR::DescribeJobFlowsOutput> instance

  

This API is deprecated and will eventually be removed. We recommend you
use ListClusters, DescribeCluster, ListSteps, ListInstanceGroups and
ListBootstrapActions instead.

DescribeJobFlows returns a list of job flows that match all of the
supplied parameters. The parameters can include a list of job flow IDs,
job flow states, and restrictions on job flow creation date and time.

Regardless of supplied parameters, only job flows created within the
last two months are returned.

If no parameters are supplied, then job flows matching either of the
following criteria are returned:

=over

=item * Job flows created and completed in the last two weeks

=item * Job flows created within the last two months that are in one of
the following states: C<RUNNING>, C<WAITING>, C<SHUTTING_DOWN>,
C<STARTING>

=back

Amazon Elastic MapReduce can return a maximum of 512 job flow
descriptions.











=head2 DescribeStep(ClusterId => Str, StepId => Str)

Each argument is described in detail in: L<Paws::EMR::DescribeStep>

Returns: a L<Paws::EMR::DescribeStepOutput> instance

  

Provides more detail about the cluster step.











=head2 ListBootstrapActions(ClusterId => Str, [Marker => Str])

Each argument is described in detail in: L<Paws::EMR::ListBootstrapActions>

Returns: a L<Paws::EMR::ListBootstrapActionsOutput> instance

  

Provides information about the bootstrap actions associated with a
cluster.











=head2 ListClusters([ClusterStates => ArrayRef[Str], CreatedAfter => Str, CreatedBefore => Str, Marker => Str])

Each argument is described in detail in: L<Paws::EMR::ListClusters>

Returns: a L<Paws::EMR::ListClustersOutput> instance

  

Provides the status of all clusters visible to this AWS account. Allows
you to filter the list of clusters based on certain criteria; for
example, filtering by cluster creation date and time or by status. This
call returns a maximum of 50 clusters per call, but returns a marker to
track the paging of the cluster list across multiple ListClusters
calls.











=head2 ListInstanceGroups(ClusterId => Str, [Marker => Str])

Each argument is described in detail in: L<Paws::EMR::ListInstanceGroups>

Returns: a L<Paws::EMR::ListInstanceGroupsOutput> instance

  

Provides all available details about the instance groups in a cluster.











=head2 ListInstances(ClusterId => Str, [InstanceGroupId => Str, InstanceGroupTypes => ArrayRef[Str], Marker => Str])

Each argument is described in detail in: L<Paws::EMR::ListInstances>

Returns: a L<Paws::EMR::ListInstancesOutput> instance

  

Provides information about the cluster instances that Amazon EMR
provisions on behalf of a user when it creates the cluster. For
example, this operation indicates when the EC2 instances reach the
Ready state, when instances become available to Amazon EMR to use for
jobs, and the IP addresses for cluster instances, etc.











=head2 ListSteps(ClusterId => Str, [Marker => Str, StepIds => ArrayRef[Str], StepStates => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EMR::ListSteps>

Returns: a L<Paws::EMR::ListStepsOutput> instance

  

Provides a list of steps for the cluster.











=head2 ModifyInstanceGroups([InstanceGroups => ArrayRef[Paws::EMR::InstanceGroupModifyConfig]])

Each argument is described in detail in: L<Paws::EMR::ModifyInstanceGroups>

Returns: nothing

  

ModifyInstanceGroups modifies the number of nodes and configuration
settings of an instance group. The input parameters include the new
target instance count for the group and the instance group ID. The call
will either succeed or fail atomically.











=head2 RemoveTags(ResourceId => Str, TagKeys => ArrayRef[Str])

Each argument is described in detail in: L<Paws::EMR::RemoveTags>

Returns: a L<Paws::EMR::RemoveTagsOutput> instance

  

Removes tags from an Amazon EMR resource. Tags make it easier to
associate clusters in various ways, such as grouping clusters to track
your Amazon EMR resource allocation costs. For more information, see
Tagging Amazon EMR Resources.

The following example removes the stack tag with value Prod from a
cluster:











=head2 RunJobFlow(Instances => Paws::EMR::JobFlowInstancesConfig, Name => Str, [AdditionalInfo => Str, AmiVersion => Str, BootstrapActions => ArrayRef[Paws::EMR::BootstrapActionConfig], JobFlowRole => Str, LogUri => Str, NewSupportedProducts => ArrayRef[Paws::EMR::SupportedProductConfig], ServiceRole => Str, Steps => ArrayRef[Paws::EMR::StepConfig], SupportedProducts => ArrayRef[Str], Tags => ArrayRef[Paws::EMR::Tag], VisibleToAllUsers => Bool])

Each argument is described in detail in: L<Paws::EMR::RunJobFlow>

Returns: a L<Paws::EMR::RunJobFlowOutput> instance

  

RunJobFlow creates and starts running a new job flow. The job flow will
run the steps specified. Once the job flow completes, the cluster is
stopped and the HDFS partition is lost. To prevent loss of data,
configure the last step of the job flow to store results in Amazon S3.
If the JobFlowInstancesConfig C<KeepJobFlowAliveWhenNoSteps> parameter
is set to C<TRUE>, the job flow will transition to the WAITING state
rather than shutting down once the steps have completed.

For additional protection, you can set the JobFlowInstancesConfig
C<TerminationProtected> parameter to C<TRUE> to lock the job flow and
prevent it from being terminated by API call, user intervention, or in
the event of a job flow error.

A maximum of 256 steps are allowed in each job flow.

If your job flow is long-running (such as a Hive data warehouse) or
complex, you may require more than 256 steps to process your data. You
can bypass the 256-step limitation in various ways, including using the
SSH shell to connect to the master node and submitting queries directly
to the software running on the master node, such as Hive and Hadoop.
For more information on how to do this, go to Add More than 256 Steps
to a Job Flow in the I<Amazon Elastic MapReduce Developer's Guide>.

For long running job flows, we recommend that you periodically store
your results.











=head2 SetTerminationProtection(JobFlowIds => ArrayRef[Str], TerminationProtected => Bool)

Each argument is described in detail in: L<Paws::EMR::SetTerminationProtection>

Returns: nothing

  

SetTerminationProtection locks a job flow so the Amazon EC2 instances
in the cluster cannot be terminated by user intervention, an API call,
or in the event of a job-flow error. The cluster still terminates upon
successful completion of the job flow. Calling SetTerminationProtection
on a job flow is analogous to calling the Amazon EC2
DisableAPITermination API on all of the EC2 instances in a cluster.

SetTerminationProtection is used to prevent accidental termination of a
job flow and to ensure that in the event of an error, the instances
will persist so you can recover any data stored in their ephemeral
instance storage.

To terminate a job flow that has been locked by setting
SetTerminationProtection to C<true>, you must first unlock the job flow
by a subsequent call to SetTerminationProtection in which you set the
value to C<false>.

For more information, go to Protecting a Job Flow from Termination in
the I<Amazon Elastic MapReduce Developer's Guide.>











=head2 SetVisibleToAllUsers(JobFlowIds => ArrayRef[Str], VisibleToAllUsers => Bool)

Each argument is described in detail in: L<Paws::EMR::SetVisibleToAllUsers>

Returns: nothing

  

Sets whether all AWS Identity and Access Management (IAM) users under
your account can access the specified job flows. This action works on
running job flows. You can also set the visibility of a job flow when
you launch it using the C<VisibleToAllUsers> parameter of RunJobFlow.
The SetVisibleToAllUsers action can be called only by an IAM user who
created the job flow or the AWS account that owns the job flow.











=head2 TerminateJobFlows(JobFlowIds => ArrayRef[Str])

Each argument is described in detail in: L<Paws::EMR::TerminateJobFlows>

Returns: nothing

  

TerminateJobFlows shuts a list of job flows down. When a job flow is
shut down, any step not yet completed is canceled and the EC2 instances
on which the job flow is running are stopped. Any log files not already
saved are uploaded to Amazon S3 if a LogUri was specified when the job
flow was created.

The maximum number of JobFlows allowed is 10. The call to
TerminateJobFlows is asynchronous. Depending on the configuration of
the job flow, it may take up to 5-20 minutes for the job flow to
completely terminate and release allocated resources, such as Amazon
EC2 instances.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

