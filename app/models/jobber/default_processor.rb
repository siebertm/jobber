class Jobber::DefaultProcessor
  def self.call(job, result)
    Rails.logger.warn "Default processor used!"
  end
end
