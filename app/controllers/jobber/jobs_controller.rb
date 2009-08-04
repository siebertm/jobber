class Jobber::JobsController < ApplicationController
  def self.locker(arg = nil, &block)
    @@locker_block = arg || block
  end


  def create
    job = Jobber::Job.get(params[:skill].to_s.split)

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

  def locker
    @@locker_block ? @@locker_block.call : "anonymous"
  end
end
