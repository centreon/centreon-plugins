package com.centreon.connector.as400.dispatcher.check;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Assert;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import org.mockito.Mockito;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;

import com.centreon.connector.as400.check.handler.ICommandHandler;
import com.centreon.connector.as400.check.handler.IDiskHandler;
import com.centreon.connector.as400.check.handler.IJobHandler;
import com.centreon.connector.as400.check.handler.IJobQueueHandler;
import com.centreon.connector.as400.check.handler.IMessageQueueHandler;
import com.centreon.connector.as400.check.handler.ISubSystemHandler;
import com.centreon.connector.as400.check.handler.ISystemHandler;

public class TestCheckHandlerRunnable extends CheckHandlerRunnable {

	public TestCheckHandlerRunnable() {
		super(null, null);

	}

	@BeforeClass
	public static void setUpBeforeClass() throws Exception {

	}

	@AfterClass
	public static void tearDownAfterClass() throws Exception {
	}

	@Before
	public void setUp() throws Exception {
		new ResponseData(ResponseData.statusOk, "OK");

		final ISubSystemHandler subSystemHandler = Mockito.mock(ISubSystemHandler.class, new Answer<ResponseData>() {
			@Override
			public ResponseData answer(final InvocationOnMock invocation) throws Throwable {
				return new ResponseData(ResponseData.statusOk, "OK");
			}
		});
		final ISystemHandler systemHandler = Mockito.mock(ISystemHandler.class, new Answer<ResponseData>() {
			@Override
			public ResponseData answer(final InvocationOnMock invocation) throws Throwable {
				return new ResponseData(ResponseData.statusOk, "OK");
			}
		});
		final IJobHandler jobHandler = Mockito.mock(IJobHandler.class, new Answer<ResponseData>() {
			@Override
			public ResponseData answer(final InvocationOnMock invocation) throws Throwable {
				return new ResponseData(ResponseData.statusOk, "OK");
			}
		});
		final IDiskHandler diskHandler = Mockito.mock(IDiskHandler.class, new Answer<ResponseData>() {
			@Override
			public ResponseData answer(final InvocationOnMock invocation) throws Throwable {
				return new ResponseData(ResponseData.statusOk, "OK");
			}
		});
		final ICommandHandler commandHandler = Mockito.mock(ICommandHandler.class, new Answer<ResponseData>() {
			@Override
			public ResponseData answer(final InvocationOnMock invocation) throws Throwable {
				return new ResponseData(ResponseData.statusOk, "OK");
			}
		});
		final IMessageQueueHandler messageQueueHandler = Mockito.mock(IMessageQueueHandler.class,
				new Answer<ResponseData>() {
					@Override
					public ResponseData answer(final InvocationOnMock invocation) throws Throwable {
						return new ResponseData(ResponseData.statusOk, "OK");
					}
				});
		final IJobQueueHandler jobQueueHandler = Mockito.mock(IJobQueueHandler.class, new Answer<ResponseData>() {
			@Override
			public ResponseData answer(final InvocationOnMock invocation) throws Throwable {
				return new ResponseData(ResponseData.statusOk, "OK");
			}
		});

		this.checkDispatcher = Mockito.mock(CheckDispatcher.class);

		Mockito.when(this.checkDispatcher.getJobHandler()).thenReturn(jobHandler);
		Mockito.when(this.checkDispatcher.getCommandHandler()).thenReturn(commandHandler);
		Mockito.when(this.checkDispatcher.getSubSystemHandler()).thenReturn(subSystemHandler);
		Mockito.when(this.checkDispatcher.getDiskHandler()).thenReturn(diskHandler);
		Mockito.when(this.checkDispatcher.getSystemHandler()).thenReturn(systemHandler);
		Mockito.when(this.checkDispatcher.getMessageQueueHandler()).thenReturn(messageQueueHandler);
		Mockito.when(this.checkDispatcher.getJobQueueHandler()).thenReturn(jobQueueHandler);
	}

	@After
	public void tearDown() throws Exception {
	}

	private void testCommand(final String command, final int exceptedStatus) {
		final ResponseData data = this.handleAs400Args(command);
		Assert.assertEquals(data.getMessage(), exceptedStatus, data.getCode());
	}

	@Test
	public void testListDisks() throws NumberFormatException, Exception {
		this.testCommand("listDisks", ResponseData.statusError);
	}

	@Test
	public void testListSubsystems() throws NumberFormatException, Exception {
		this.testCommand("listSubsystems", ResponseData.statusOk);
	}

	@Test
	public void testListJobs() throws NumberFormatException, Exception {
		this.testCommand("listJobs", ResponseData.statusOk);
	}

	@Test
	public void testGetErrorMessageQueue() throws NumberFormatException, Exception {
		this.testCommand("getErrorMessageQueue", ResponseData.statusError);
	}

	@Test
	public void testPageFault() throws NumberFormatException, Exception {
		this.testCommand("pageFault", ResponseData.statusOk);
	}

	@Test
	public void testGetJobQueues() throws NumberFormatException, Exception {
		this.testCommand("getJobQueues", ResponseData.statusError);
	}

	@Test
	public void testExecuteCommand() throws NumberFormatException, Exception {
		this.testCommand("executeCommand", ResponseData.statusError);
	}

	@Test
	public void testUnknown() throws NumberFormatException, Exception {
		this.testCommand("blabla", ResponseData.statusError);
	}
}
