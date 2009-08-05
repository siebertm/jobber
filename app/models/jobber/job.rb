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

  def self.register_processor(type, klass = nil, &block)
    obj = klass || block
    raise(ArgumentError, "#{obj} does not respond to :call") unless obj.respond_to?(:call)

    self.processors ||= {}
    self.processors[type.to_sym] = klass
  end

  def self.processor_for(type)
    self.processors ||= {}
    self.processors[type.to_sym] || Jobber::DefaultProcessor
  end


  def self.get(*types)
    Jobber::Job.available.with_types(types.flatten).first
  end

  def as_json(*args)
    {
      :id => id,
      :type => type,
      :data => data
    }
  end

  def locked?
    locked_by.present? && locked_at.present? && locked_at > 10.minutes.ago
  end

  def acquire!(locker)
    self.locked_by = locker
    self.locked_at = Time.now
    save!
  end

  def done!(result = nil)
    self.class.processor_for(type).process(self, result)
    destroy
  end


end
