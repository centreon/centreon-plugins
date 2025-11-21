//package com.centreon.connector.as400.check.handler.msgqueue;
//
//import java.sql.Date;
//import java.sql.SQLException;
//import java.util.Calendar;
//
//import org.junit.After;
//import org.junit.AfterClass;
//import org.junit.Before;
//import org.junit.BeforeClass;
//import org.junit.Test;
//import org.mockito.Mockito;
//
//import com.ibm.as400.access.QueuedMessage;
//
//public class LocalDbTest {
//
//	@BeforeClass
//	public static void setUpBeforeClass() throws Exception {
//	}
//
//	@AfterClass
//	public static void tearDownAfterClass() throws Exception {
//	}
//
//	@Before
//	public void setUp() throws Exception {
//	}
//
//	@After
//	public void tearDown() throws Exception {
//	}
//
//	private QueuedMessage createMockedObject(final String msgId, final int severity, final String text, final int type, final String user, final Date date,
//			final Date createDate) {
//
//		final QueuedMessage msg = Mockito.mock(QueuedMessage.class);
//		Mockito.when(msg.getID()).thenReturn(msgId);
//		Mockito.when(msg.getSeverity()).thenReturn(severity);
//		Mockito.when(msg.getText()).thenReturn(text);
//		Mockito.when(msg.getType()).thenReturn(type);
//		Mockito.when(msg.getUser()).thenReturn(user);
//		Mockito.when(msg.getDate()).thenReturn(new Calendar.Builder().setDate(1, 1, 1).build());
//		Mockito.when(msg.getCreateDate()).thenReturn(createDate);
//
//		return msg;
//	}
//
//	@Test
//	public void testAddEntry() throws SQLException {
//		final LocalDb db = new LocalDb("/tmp/test123");
//		final QueuedMessage msg = this.createMockedObject("123", 5, "This is an output", 2, "user", new Date(0), new Date(0));
//		db.addEntry(msg);
//	}
//
//	@Test
//	public void testGetQueuedMessage() {
//		// Assert.fail("Not yet implemented");
//	}
//
//}
