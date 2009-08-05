class Jobber::JobsController < ApplicationController
  unloadable

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
    if job.locked? && job.locked_by == locker_name
      job.done!
      render :nothing => true
    else
      render :nothing => true, :status => :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end


  protected

  def fetch_job(skill)
    job_scope.get(skill.to_s.split)
  end

  def job_scope
    if Jobber::Config.scope_proc
      Jobber::Job.scoped(instance_exec(&Jobber::Config.scope_proc))
    else
      Jobber::Job
    end
  end

  def locker_name
    Jobber::Config.locker_proc ? instance_exec(&Jobber::Config.locker_proc) : "anonymous"
  end
end
