
Factory.define :job, :class => Jobber::Job do |j|
  j.add_attribute :type, "default"
  j.run_at 10.minutes.ago
end

Factory.define :locked_job, :parent => :job do |j|
  j.locked_at 1.minute.ago
  j.locked_by "anonymous"
end

