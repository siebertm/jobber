class Jobber::DefaultProcessor
  def self.process(job, result)
    Rails.logger.warn "Default processor used!"
  end
end
