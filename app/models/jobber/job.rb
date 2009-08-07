class Jobber::Job < ActiveRecord::Base
  set_table_name :jobber_jobs
  set_inheritance_column :not_sti
  class_inheritable_hash :processors
  serialize :data

  validates_presence_of :type

  named_scope :available, lambda {
    {
      :conditions => ["locked_at IS NULL OR locked_at<?", 10.minutes.ago],
      :order => "run_at ASC, id ASC"
    }
  }

  named_scope :with_types, lambda { |types|
    if types.nil? || types.empty?
      {}
    else
      {:conditions => {:type => types.map(&:to_s)}}
    end
  }

  #
  # Registers a processor object for a specific job type
  #
  # When jobs are done, in most environments the results should
  # not be discarded but stored somewhere. To accomplish this,
  # one should attach a processor object to a job type, which,
  # when called, handles the results as needed.
  #
  # The *type* parameter is the type that the processor should be
  # used for (there can only be one processor per type).
  #
  # The *klass* parameter is just an object which must respond to
  # *call*. The call method gets 2 arguments: the first is the job
  # instance, the second argument is the result passed to the
  # done method:
  #
  #   class BankAccountTransferProcessor
  #     def self.call(job, result)
  #       ...
  #     end
  #   end
  #
  #   Jobber::Job.register_processor :transfer, BankAccountTransferProcessor
  #
  # Instead of the klass parameter, you can even pass a block
  # to the method, which is then used as the processor (hence the
  # need for a *call* method):
  #
  #   Jobber::Job.register_processor :transfer do |job, result|
  #     ...
  #   end
  #
  def self.register_processor(type, klass = nil, &block)
    obj = klass || block
    raise(ArgumentError, "#{obj} does not respond to :call") unless obj.respond_to?(:call)

    self.processors ||= {}
    self.processors[type.to_sym] = klass
  end


  #
  # Returns the next available job
  #
  # Determines the next available job, filtered by type and returns
  # that job object
  #
  # The filtering for types can be neccessary to just look at
  # specific types (possibly because one client can only do certain
  # types of jobs)
  #
  # *types* is an array of strings which must match jobs
  #
  #   Jobber::Job.get("transfer", "deposit")
  # equals
  #   Jobber::Job.get(["transfer", "deposit"])
  # equals
  #   Jobber::Job.get(:transfer, :deposit)
  #
  # Returns a Job or nil if none was found
  #
  def self.get(*types)
    Jobber::Job.available.with_types(types.flatten).first
  end

  # enqueues a new job
  def self.enqueue!(args)
    create!({:run_at => Time.now}.merge(args))
  end


  #
  # Acquires the job (locks it for a client)
  #
  # When acquiring a job, the job is locked and marked as "will be
  # done soon" by the *locker*. The *locker* argument specifies which
  # value to set for the *locked_by* column
  #
  # Saves the Job
  #
  def acquire!(locker)
    self.locked_by = locker
    self.locked_at = Time.now
    save!
  end

  #
  # Sets the job as done and processes the result with a registered processor
  #
  # When the job is done, this method should be called with the
  # result. The result is then passed to the processor for that job
  # type.
  #
  # After processing, the Job is destroyed.
  def done!(result = nil)
    self.class.processor_for(type).call(self, result)
    destroy
  end

  #
  # Returns a hash representation of the Job
  #
  def as_json(*args)
    {
      :id => id,
      :type => type,
      :data => data
    }
  end

  #
  # Returns whether the job has been locked
  #
  def locked?
    locked_by.present? && locked_at.present? && locked_at > 10.minutes.ago
  end


  protected

  def self.processor_for(type)
    self.processors ||= {}
    self.processors[type.to_sym] || Jobber::DefaultProcessor
  end


end
