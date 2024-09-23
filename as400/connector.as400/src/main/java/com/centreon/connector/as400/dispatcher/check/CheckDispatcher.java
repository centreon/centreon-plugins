/*
 * Copyright 2021 Centreon (http://www.centreon.com/)
 *
 * Centreon is a full-fledged industry-strength solution that meets
 * the needs in IT infrastructure and application monitoring for
 * service performance.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License. 
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, 
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
 * See the License for the specific language governing permissions and 
 * limitations under the License.
 */

package com.centreon.connector.as400.dispatcher.check;

import java.io.IOException;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.RejectedExecutionHandler;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import com.ibm.as400.access.AS400SecurityException;
import com.centreon.connector.as400.Conf;
import com.centreon.connector.as400.check.handler.ICachedMessageQueueHandler;
import com.centreon.connector.as400.check.handler.ICommandHandler;
import com.centreon.connector.as400.check.handler.IDiskHandler;
import com.centreon.connector.as400.check.handler.IJobHandler;
import com.centreon.connector.as400.check.handler.IJobQueueHandler;
import com.centreon.connector.as400.check.handler.IMessageQueueHandler;
import com.centreon.connector.as400.check.handler.ISubSystemHandler;
import com.centreon.connector.as400.check.handler.ISystemHandler;
import com.centreon.connector.as400.check.handler.impl.CommandHandler;
import com.centreon.connector.as400.check.handler.impl.DiskHandler;
import com.centreon.connector.as400.check.handler.impl.JobHandler;
import com.centreon.connector.as400.check.handler.impl.JobQueueHandler;
import com.centreon.connector.as400.check.handler.impl.SubSystemHandler;
import com.centreon.connector.as400.check.handler.impl.SystemHandler;
import com.centreon.connector.as400.check.handler.msgqueue.CachedMessageQueueHandler;
import com.centreon.connector.as400.check.handler.msgqueue.MessageQueueHandler;
import com.centreon.connector.as400.check.handler.wrkprb.WorkWithProblemHandler;
import com.centreon.connector.as400.client.impl.NetworkClient;

import io.undertow.server.HttpServerExchange;

/**
 * @author Lamotte Jean-Baptiste
 */
public class CheckDispatcher {

    private static class DefaultThreadFactory implements ThreadFactory {
        private static final AtomicInteger poolNumber = new AtomicInteger(1);
        private final ThreadGroup group;
        private final AtomicInteger threadNumber = new AtomicInteger(1);
        private final String namePrefix;

        private DefaultThreadFactory(final String host, final String type) {
            final SecurityManager s = System.getSecurityManager();
            this.group = (s != null) ? s.getThreadGroup() : Thread.currentThread().getThreadGroup();
            this.namePrefix = "" + host + "-pool-" + type + "-" + DefaultThreadFactory.poolNumber.getAndIncrement()
                    + "-thread-";
        }

        @Override
        public Thread newThread(final Runnable r) {
            final Thread t = new Thread(this.group, r, this.namePrefix + this.threadNumber.getAndIncrement(), 0);
            if (t.isDaemon()) {
                t.setDaemon(false);
            }
            if (t.getPriority() != Thread.NORM_PRIORITY) {
                t.setPriority(Thread.NORM_PRIORITY);
            }
            return t;
        }
    }

    private String host = null;
    private String login = null;
    private String password = null;

    private volatile ConcurrentHashMap<String, Long> filter = new ConcurrentHashMap<String, Long>();

    private ISubSystemHandler subSystemHandler = null;
    private ISystemHandler systemHandler = null;
    private IJobHandler jobHandler = null;
    private IDiskHandler diskHandler = null;
    private ICommandHandler commandHandler = null;

    private ThreadPoolExecutor executorGlobal = null;
    private ThreadPoolExecutor executorJobs = null;
    private ThreadPoolExecutor executorDisk = null;

    class ThreadPoolExecutorPostFilter extends ThreadPoolExecutor {
        public ThreadPoolExecutorPostFilter(final int corePoolSize, final int maximumPoolSize, final long keepAliveTime,
                final TimeUnit unit, final BlockingQueue<Runnable> workQueue, final RejectedExecutionHandler handler) {
            super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue, handler);
        }

        public ThreadPoolExecutorPostFilter(final int corePoolSize, final int maximumPoolSize, final long keepAliveTime,
                final TimeUnit unit, final BlockingQueue<Runnable> workQueue) {
            super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue);
        }

        public ThreadPoolExecutorPostFilter(final int corePoolSize, final int maximumPoolSize, final long keepAliveTime,
                final TimeUnit unit, final BlockingQueue<Runnable> workQueue, final ThreadFactory threadFactory) {
            super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue, threadFactory);
        }

        public ThreadPoolExecutorPostFilter(final int corePoolSize, final int maximumPoolSize, final long keepAliveTime,
                final TimeUnit unit, final BlockingQueue<Runnable> workQueue, final ThreadFactory threadFactory,
                final RejectedExecutionHandler handler) {
            super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue, threadFactory, handler);
        }

        @Override
        protected void afterExecute(final Runnable r, final Throwable t) {
            if (r instanceof CheckHandlerRunnable) {
                final CheckHandlerRunnable runnable = (CheckHandlerRunnable) r;
                final NetworkClient client = runnable.getClient();
                final String rawRequest = client.getRawRequest();

                CheckDispatcher.this.filter.remove(rawRequest);
            }
            super.afterExecute(r, t);
        }
    }

    public CheckDispatcher(final String host, final String login, final String password) {
        this.host = host;
        this.login = login;
        this.password = password;

        this.executorGlobal = new ThreadPoolExecutorPostFilter(5, 10, Conf.workerQueueTimeout, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<Runnable>());
        this.executorGlobal.setThreadFactory(new DefaultThreadFactory(host, "global"));

        this.executorJobs = new ThreadPoolExecutorPostFilter(1, 1, Conf.workerQueueTimeout, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<Runnable>());
        this.executorJobs.setThreadFactory(new DefaultThreadFactory(host, "job"));

        this.executorDisk = new ThreadPoolExecutorPostFilter(1, 1, Conf.workerQueueTimeout, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<Runnable>());
        this.executorDisk.setThreadFactory(new DefaultThreadFactory(host, "disk"));
    }

    public String getHost() {
        return this.host;
    }

    public String getLogin() {
        return this.login;
    }

    public String getPassword() {
        return this.password;
    }

    public synchronized void dispatch(final NetworkClient client) {

        if (this.filter.containsKey(client.getRawRequest())) {
            final long time = this.filter.get(client.getRawRequest());
            client.writeAnswer(new ResponseData(ResponseData.statusError, "Previous request pending (started "
                    + (System.currentTimeMillis() - time)
                    + " ms ago). Increase your check interval, and nagios check timeout. Also check your bandwidth availability"));
            return;
        }

        this.filter.put(client.getRawRequest(), System.currentTimeMillis());

        final String command = client.getAs400CheckType();

        if (command.equalsIgnoreCase("listJobs")) {
            client.getExchange().dispatch(this.executorJobs, new CheckHandlerRunnable(client, this));
        } else if (command.equalsIgnoreCase("listDisks")) {
            client.getExchange().dispatch(this.executorDisk, new CheckHandlerRunnable(client, this));
        } else {
            client.getExchange().dispatch(this.executorGlobal, new CheckHandlerRunnable(client, this));
        }
    }

    public ICommandHandler getCommandHandler() throws AS400SecurityException, IOException {
        if (this.commandHandler == null) {
            this.commandHandler = new CommandHandler(this.host, this.login, this.password);
        }
        return this.commandHandler;
    }

    public IDiskHandler getDiskHandler() throws AS400SecurityException, IOException {
        if (this.diskHandler == null) {
            this.diskHandler = new DiskHandler(this.host, this.login, this.password);
        }
        return this.diskHandler;
    }

    public IJobHandler getJobHandler() throws AS400SecurityException, IOException {
        if (this.jobHandler == null) {
            this.jobHandler = new JobHandler(this.host, this.login, this.password);
        }
        return this.jobHandler;
    }

    public ISubSystemHandler getSubSystemHandler() throws AS400SecurityException, IOException {
        if (this.subSystemHandler == null) {
            this.subSystemHandler = new SubSystemHandler(this.host, this.login, this.password);
        }
        return this.subSystemHandler;
    }

    public ISystemHandler getSystemHandler() throws AS400SecurityException, IOException {
        if (this.systemHandler == null) {
            this.systemHandler = new SystemHandler(this.host, this.login, this.password);
        }
        return this.systemHandler;
    }

    public ICachedMessageQueueHandler getCachedMessageQueueHandler() throws AS400SecurityException, IOException {
        return new CachedMessageQueueHandler(this.host, this.login, this.password);
    }

    public IMessageQueueHandler getMessageQueueHandler() throws AS400SecurityException, IOException {
        return new MessageQueueHandler(this.host, this.login, this.password);
    }

    public IJobQueueHandler getJobQueueHandler() throws AS400SecurityException, IOException {
        return new JobQueueHandler(this.host, this.login, this.password);
    }

    public WorkWithProblemHandler getWrkPrbHandler() throws AS400SecurityException, IOException {
        return new WorkWithProblemHandler(this.host, this.login, this.password);
    }
}
