// package com.centreon.connector.as400.client;
//
// import java.io.IOException;
//
// import org.junit.After;
// import org.junit.AfterClass;
// import org.junit.Before;
// import org.junit.BeforeClass;
// import org.junit.Test;
// import org.mockito.Mockito;
//
// import com.ibm.as400.access.AS400SecurityException;
// import com.centreon.connector.as400.client.impl.CommandLineClient;
// import com.centreon.connector.as400.daemon.DelayedConnectionException;
// import com.centreon.connector.as400.dispatcher.check.CheckDispatcher;
// import com.centreon.connector.as400.dispatcher.check.CheckHandlerRunnable;
//
// public class TestClient {
// @BeforeClass
// public static void setUpBeforeClass() throws Exception {
// }
//
// @AfterClass
// public static void tearDownAfterClass() throws Exception {
// }
//
// @Before
// public void setUp() throws Exception {
//
// }
//
// @After
// public void tearDown() throws Exception {
// }
//
// @Test
// public void testCommandLine() throws AS400SecurityException, IOException,
// DelayedConnectionException, Exception {
// final String args[] = { "-I", "-H", "localhost", "--login", "test",
// "--password", "test", "-C", "cpu", "-A", "80,90" };
// final IClient client = new CommandLineClient(args);
// // ClientDispatcherImpl.getInstance().dispatch(client);
//
// final CheckDispatcher dispatcher = Mockito.mock(CheckDispatcher.class);
//
// final CheckHandlerRunnable runnable = new CheckHandlerRunnable(client,
// dispatcher);
// runnable.run();
// // final CheckDispatcher checkDispatcher = new
// // CheckDispatcher("localhost", "test", "test");
// // checkDispatcher.dispatch(client);
// }
// }
