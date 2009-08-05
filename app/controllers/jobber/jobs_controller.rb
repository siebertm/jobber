class Jobber::JobsController < ApplicationController
  @@locker_proc = nil
  @@scope_proc = nil

  def self.locker_name(arg = nil, &block)
    @@locker_proc = arg || block
  end

  def self.set_scope(arg = nil, &block)
    @@scope_proc = arg || block
  end


  def create
    job = fetch_job(params[:skill])

    if job
      job.acquire!(locker_name)
      render :json => job.as_json
    else
      render :nothing => true
    end
  end


  def update
    job = Jobber::Job.find(params[:id])
    job.done!

    render :nothing => true
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end


  protected

  def fetch_job(skill)
    job_scope.get(skill.to_s.split)
  end

  def job_scope
    if @@scope_proc
      Jobber::Job.scoped(instance_exec(&@@scope_proc))
    else
      Jobber::Job
    end
  end

  def locker_name
    @@locker_proc ? instance_exec(&@@locker_proc) : "anonymous"
  end
end
