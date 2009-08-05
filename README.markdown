Jobber - A Rails plugin for distributed job queues
==================================================

Jobber aims to be a Rails engine-type plugin which supplies your application with a way to distribute jobs and aggregate the results.

Jobs are created by the Rails application (currently, they can't be created by HTTP request, and I don't think it ever will do this) and then sent out
to the job workers which will work off their job and then send back the result to the server.  handling the results is not done by the plugin, but you
can register request Processors (objects which respond to the message :call and take 2 arguments) which then handle the results

*NOTE*: this plugin is currently WIP and not even a plugin. Possibly it won't even work for you :-)


Installation
------------

    ./script/plugin install git://github.com/siebertm/jobber.git

Migration
---------

You'll have to have at least the following database table:

    create_table :jobber_jobs do |t|
      t.integer  :priority, :default => 0
      t.integer  :attempts, :default => 0
      t.string   :type
      t.text     :data

      t.datetime :run_at
      t.datetime :locked_at
      t.string   :locked_by

      t.timestamps
    end

Feel free to add more columns specific to your application.


Configuration
-------------

To configure the plugin, there are currently two extension points. The first one is the ``locker_name``, which lets you decide which string is to be
written into the ``locked_by`` column. This is to identify the client (e.g. the currently logged in user) which accepts a job and the submits the
results. Only the client who locked the job can send back the results.

To set the ``locker_name``, just add the following line to your config/initializers/jobber.rb:

    Jobber::Config.set_locker_name do
      "user_#{current_user.id}"
    end

The second extension point can be used to restrict which jobs will be send to the client. In fact, the return value of the passed block is passed to
Job.scoped. To set the scope, just add the following lines to your config/initializers/jobber.rb:

    Jobber:Config.set_scope do
      {:conditions => {:user_id => current_user.id}}
    end

Both blocks are instance\_eval'ed in the controller context, so you'll have access to everything a controller action or before\_filter would (session,
params, current\_user, etc).


