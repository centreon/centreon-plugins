package Paws::ElasticBeanstalk {
  use Moose;
  sub service { 'elasticbeanstalk' }
  sub version { '2010-12-01' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  
  sub AbortEnvironmentUpdate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::AbortEnvironmentUpdate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CheckDNSAvailability {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::CheckDNSAvailability', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateApplication {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::CreateApplication', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateApplicationVersion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::CreateApplicationVersion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateConfigurationTemplate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::CreateConfigurationTemplate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateEnvironment {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::CreateEnvironment', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateStorageLocation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::CreateStorageLocation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteApplication {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DeleteApplication', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteApplicationVersion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DeleteApplicationVersion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteConfigurationTemplate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DeleteConfigurationTemplate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteEnvironmentConfiguration {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DeleteEnvironmentConfiguration', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeApplications {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DescribeApplications', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeApplicationVersions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DescribeApplicationVersions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeConfigurationOptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DescribeConfigurationOptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeConfigurationSettings {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DescribeConfigurationSettings', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEnvironmentResources {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DescribeEnvironmentResources', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEnvironments {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DescribeEnvironments', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::DescribeEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAvailableSolutionStacks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::ListAvailableSolutionStacks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RebuildEnvironment {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::RebuildEnvironment', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RequestEnvironmentInfo {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::RequestEnvironmentInfo', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RestartAppServer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::RestartAppServer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RetrieveEnvironmentInfo {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::RetrieveEnvironmentInfo', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SwapEnvironmentCNAMEs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::SwapEnvironmentCNAMEs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub TerminateEnvironment {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::TerminateEnvironment', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateApplication {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::UpdateApplication', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateApplicationVersion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::UpdateApplicationVersion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateConfigurationTemplate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::UpdateConfigurationTemplate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateEnvironment {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::UpdateEnvironment', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ValidateConfigurationSettings {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticBeanstalk::ValidateConfigurationSettings', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk - Perl Interface to AWS AWS Elastic Beanstalk

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('ElasticBeanstalk')->new;
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



AWS Elastic Beanstalk

This is the AWS Elastic Beanstalk API Reference. This guide provides
detailed information about AWS Elastic Beanstalk actions, data types,
parameters, and errors.

AWS Elastic Beanstalk is a tool that makes it easy for you to create,
deploy, and manage scalable, fault-tolerant applications running on
Amazon Web Services cloud resources.

For more information about this product, go to the AWS Elastic
Beanstalk details page. The location of the latest AWS Elastic
Beanstalk WSDL is
http://elasticbeanstalk.s3.amazonaws.com/doc/2010-12-01/AWSElasticBeanstalk.wsdl.
To install the Software Development Kits (SDKs), Integrated Development
Environment (IDE) Toolkits, and command line tools that enable you to
access the API, go to Tools for Amazon Web Services.

B<Endpoints>

For a list of region-specific endpoints that AWS Elastic Beanstalk
supports, go to Regions and Endpoints in the I<Amazon Web Services
Glossary>.










=head1 METHODS

=head2 AbortEnvironmentUpdate([EnvironmentId => Str, EnvironmentName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::AbortEnvironmentUpdate>

Returns: nothing

  

Cancels in-progress environment configuration update or application
version deployment.











=head2 CheckDNSAvailability(CNAMEPrefix => Str)

Each argument is described in detail in: L<Paws::ElasticBeanstalk::CheckDNSAvailability>

Returns: a L<Paws::ElasticBeanstalk::CheckDNSAvailabilityResultMessage> instance

  

Checks if the specified CNAME is available.











=head2 CreateApplication(ApplicationName => Str, [Description => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::CreateApplication>

Returns: a L<Paws::ElasticBeanstalk::ApplicationDescriptionMessage> instance

  

Creates an application that has one configuration template named
C<default> and no application versions.











=head2 CreateApplicationVersion(ApplicationName => Str, VersionLabel => Str, [AutoCreateApplication => Bool, Description => Str, SourceBundle => Paws::ElasticBeanstalk::S3Location])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::CreateApplicationVersion>

Returns: a L<Paws::ElasticBeanstalk::ApplicationVersionDescriptionMessage> instance

  

Creates an application version for the specified application.

Once you create an application version with a specified Amazon S3
bucket and key location, you cannot change that Amazon S3 location. If
you change the Amazon S3 location, you receive an exception when you
attempt to launch an environment from the application version.











=head2 CreateConfigurationTemplate(ApplicationName => Str, TemplateName => Str, [Description => Str, EnvironmentId => Str, OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting], SolutionStackName => Str, SourceConfiguration => Paws::ElasticBeanstalk::SourceConfiguration])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::CreateConfigurationTemplate>

Returns: a L<Paws::ElasticBeanstalk::ConfigurationSettingsDescription> instance

  

Creates a configuration template. Templates are associated with a
specific application and are used to deploy different versions of the
application with the same configuration settings.

Related Topics

=over

=item * DescribeConfigurationOptions

=item * DescribeConfigurationSettings

=item * ListAvailableSolutionStacks

=back











=head2 CreateEnvironment(ApplicationName => Str, EnvironmentName => Str, [CNAMEPrefix => Str, Description => Str, OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting], OptionsToRemove => ArrayRef[Paws::ElasticBeanstalk::OptionSpecification], SolutionStackName => Str, Tags => ArrayRef[Paws::ElasticBeanstalk::Tag], TemplateName => Str, Tier => Paws::ElasticBeanstalk::EnvironmentTier, VersionLabel => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::CreateEnvironment>

Returns: a L<Paws::ElasticBeanstalk::EnvironmentDescription> instance

  

Launches an environment for the specified application using the
specified configuration.











=head2 CreateStorageLocation( => )

Each argument is described in detail in: L<Paws::ElasticBeanstalk::CreateStorageLocation>

Returns: a L<Paws::ElasticBeanstalk::CreateStorageLocationResultMessage> instance

  

Creates the Amazon S3 storage location for the account.

This location is used to store user log files.











=head2 DeleteApplication(ApplicationName => Str, [TerminateEnvByForce => Bool])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DeleteApplication>

Returns: nothing

  

Deletes the specified application along with all associated versions
and configurations. The application versions will not be deleted from
your Amazon S3 bucket.

You cannot delete an application that has a running environment.











=head2 DeleteApplicationVersion(ApplicationName => Str, VersionLabel => Str, [DeleteSourceBundle => Bool])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DeleteApplicationVersion>

Returns: nothing

  

Deletes the specified version from the specified application.

You cannot delete an application version that is associated with a
running environment.











=head2 DeleteConfigurationTemplate(ApplicationName => Str, TemplateName => Str)

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DeleteConfigurationTemplate>

Returns: nothing

  

Deletes the specified configuration template.

When you launch an environment using a configuration template, the
environment gets a copy of the template. You can delete or modify the
environment's copy of the template without affecting the running
environment.











=head2 DeleteEnvironmentConfiguration(ApplicationName => Str, EnvironmentName => Str)

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DeleteEnvironmentConfiguration>

Returns: nothing

  

Deletes the draft configuration associated with the running
environment.

Updating a running environment with any configuration changes creates a
draft configuration set. You can get the draft configuration using
DescribeConfigurationSettings while the update is in progress or if the
update fails. The C<DeploymentStatus> for the draft configuration
indicates whether the deployment is in process or has failed. The draft
configuration remains in existence until it is deleted with this
action.











=head2 DescribeApplications([ApplicationNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DescribeApplications>

Returns: a L<Paws::ElasticBeanstalk::ApplicationDescriptionsMessage> instance

  

Returns the descriptions of existing applications.











=head2 DescribeApplicationVersions([ApplicationName => Str, VersionLabels => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DescribeApplicationVersions>

Returns: a L<Paws::ElasticBeanstalk::ApplicationVersionDescriptionsMessage> instance

  

Returns descriptions for existing application versions.











=head2 DescribeConfigurationOptions([ApplicationName => Str, EnvironmentName => Str, Options => ArrayRef[Paws::ElasticBeanstalk::OptionSpecification], SolutionStackName => Str, TemplateName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DescribeConfigurationOptions>

Returns: a L<Paws::ElasticBeanstalk::ConfigurationOptionsDescription> instance

  

Describes the configuration options that are used in a particular
configuration template or environment, or that a specified solution
stack defines. The description includes the values the options, their
default values, and an indication of the required action on a running
environment if an option value is changed.











=head2 DescribeConfigurationSettings(ApplicationName => Str, [EnvironmentName => Str, TemplateName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DescribeConfigurationSettings>

Returns: a L<Paws::ElasticBeanstalk::ConfigurationSettingsDescriptions> instance

  

Returns a description of the settings for the specified configuration
set, that is, either a configuration template or the configuration set
associated with a running environment.

When describing the settings for the configuration set associated with
a running environment, it is possible to receive two sets of setting
descriptions. One is the deployed configuration set, and the other is a
draft configuration of an environment that is either in the process of
deployment or that failed to deploy.

Related Topics

=over

=item * DeleteEnvironmentConfiguration

=back











=head2 DescribeEnvironmentResources([EnvironmentId => Str, EnvironmentName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DescribeEnvironmentResources>

Returns: a L<Paws::ElasticBeanstalk::EnvironmentResourceDescriptionsMessage> instance

  

Returns AWS resources for this environment.











=head2 DescribeEnvironments([ApplicationName => Str, EnvironmentIds => ArrayRef[Str], EnvironmentNames => ArrayRef[Str], IncludedDeletedBackTo => Str, IncludeDeleted => Bool, VersionLabel => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DescribeEnvironments>

Returns: a L<Paws::ElasticBeanstalk::EnvironmentDescriptionsMessage> instance

  

Returns descriptions for existing environments.











=head2 DescribeEvents([ApplicationName => Str, EndTime => Str, EnvironmentId => Str, EnvironmentName => Str, MaxRecords => Int, NextToken => Str, RequestId => Str, Severity => Str, StartTime => Str, TemplateName => Str, VersionLabel => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::DescribeEvents>

Returns: a L<Paws::ElasticBeanstalk::EventDescriptionsMessage> instance

  

Returns list of event descriptions matching criteria up to the last 6
weeks.

This action returns the most recent 1,000 events from the specified
C<NextToken>.











=head2 ListAvailableSolutionStacks( => )

Each argument is described in detail in: L<Paws::ElasticBeanstalk::ListAvailableSolutionStacks>

Returns: a L<Paws::ElasticBeanstalk::ListAvailableSolutionStacksResultMessage> instance

  

Returns a list of the available solution stack names.











=head2 RebuildEnvironment([EnvironmentId => Str, EnvironmentName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::RebuildEnvironment>

Returns: nothing

  

Deletes and recreates all of the AWS resources (for example: the Auto
Scaling group, load balancer, etc.) for a specified environment and
forces a restart.











=head2 RequestEnvironmentInfo(InfoType => Str, [EnvironmentId => Str, EnvironmentName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::RequestEnvironmentInfo>

Returns: nothing

  

Initiates a request to compile the specified type of information of the
deployed environment.

Setting the C<InfoType> to C<tail> compiles the last lines from the
application server log files of every Amazon EC2 instance in your
environment.

Setting the C<InfoType> to C<bundle> compresses the application server
log files for every Amazon EC2 instance into a C<.zip> file. Legacy and
.NET containers do not support bundle logs.

Use RetrieveEnvironmentInfo to obtain the set of logs.

Related Topics

=over

=item * RetrieveEnvironmentInfo

=back











=head2 RestartAppServer([EnvironmentId => Str, EnvironmentName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::RestartAppServer>

Returns: nothing

  

Causes the environment to restart the application container server
running on each Amazon EC2 instance.











=head2 RetrieveEnvironmentInfo(InfoType => Str, [EnvironmentId => Str, EnvironmentName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::RetrieveEnvironmentInfo>

Returns: a L<Paws::ElasticBeanstalk::RetrieveEnvironmentInfoResultMessage> instance

  

Retrieves the compiled information from a RequestEnvironmentInfo
request.

Related Topics

=over

=item * RequestEnvironmentInfo

=back











=head2 SwapEnvironmentCNAMEs([DestinationEnvironmentId => Str, DestinationEnvironmentName => Str, SourceEnvironmentId => Str, SourceEnvironmentName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::SwapEnvironmentCNAMEs>

Returns: nothing

  

Swaps the CNAMEs of two environments.











=head2 TerminateEnvironment([EnvironmentId => Str, EnvironmentName => Str, TerminateResources => Bool])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::TerminateEnvironment>

Returns: a L<Paws::ElasticBeanstalk::EnvironmentDescription> instance

  

Terminates the specified environment.











=head2 UpdateApplication(ApplicationName => Str, [Description => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::UpdateApplication>

Returns: a L<Paws::ElasticBeanstalk::ApplicationDescriptionMessage> instance

  

Updates the specified application to have the specified properties.

If a property (for example, C<description>) is not provided, the value
remains unchanged. To clear these properties, specify an empty string.











=head2 UpdateApplicationVersion(ApplicationName => Str, VersionLabel => Str, [Description => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::UpdateApplicationVersion>

Returns: a L<Paws::ElasticBeanstalk::ApplicationVersionDescriptionMessage> instance

  

Updates the specified application version to have the specified
properties.

If a property (for example, C<description>) is not provided, the value
remains unchanged. To clear properties, specify an empty string.











=head2 UpdateConfigurationTemplate(ApplicationName => Str, TemplateName => Str, [Description => Str, OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting], OptionsToRemove => ArrayRef[Paws::ElasticBeanstalk::OptionSpecification]])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::UpdateConfigurationTemplate>

Returns: a L<Paws::ElasticBeanstalk::ConfigurationSettingsDescription> instance

  

Updates the specified configuration template to have the specified
properties or configuration option values.

If a property (for example, C<ApplicationName>) is not provided, its
value remains unchanged. To clear such properties, specify an empty
string.

Related Topics

=over

=item * DescribeConfigurationOptions

=back











=head2 UpdateEnvironment([Description => Str, EnvironmentId => Str, EnvironmentName => Str, OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting], OptionsToRemove => ArrayRef[Paws::ElasticBeanstalk::OptionSpecification], SolutionStackName => Str, TemplateName => Str, Tier => Paws::ElasticBeanstalk::EnvironmentTier, VersionLabel => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::UpdateEnvironment>

Returns: a L<Paws::ElasticBeanstalk::EnvironmentDescription> instance

  

Updates the environment description, deploys a new application version,
updates the configuration settings to an entirely new configuration
template, or updates select configuration option values in the running
environment.

Attempting to update both the release and configuration is not allowed
and AWS Elastic Beanstalk returns an C<InvalidParameterCombination>
error.

When updating the configuration settings to a new template or
individual settings, a draft configuration is created and
DescribeConfigurationSettings for this environment returns two setting
descriptions with different C<DeploymentStatus> values.











=head2 ValidateConfigurationSettings(ApplicationName => Str, OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting], [EnvironmentName => Str, TemplateName => Str])

Each argument is described in detail in: L<Paws::ElasticBeanstalk::ValidateConfigurationSettings>

Returns: a L<Paws::ElasticBeanstalk::ConfigurationSettingsValidationMessages> instance

  

Takes a set of configuration settings and either a configuration
template or environment, and determines whether those values are valid.

This action returns a list of messages indicating any errors or
warnings associated with the selection of option values.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

