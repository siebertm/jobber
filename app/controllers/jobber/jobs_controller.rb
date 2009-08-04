class Jobber::JobsController < ApplicationController
  @@locker_proc = nil
  @@scope_proc = nil
  def self.locker(arg = nil, &block)
    @@locker_proc = arg || block
  end

  def self.set_scope(arg = nil, &block)
    @@scope_proc = arg || block
  end


  def create
    job = Jobber::Job.scoped(getter_scope).get(params[:skill].to_s.split)

    if job
      job.acquire!(locker)
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

  def getter_scope
    @@scope_proc ? @@scope_proc.call : {}
  end

  def locker
    @@locker_proc ? @@locker_proc.call : "anonymous"
  end
end
