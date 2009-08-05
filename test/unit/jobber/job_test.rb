require File.join(File.dirname(__FILE__), '../../test_helper')

class Jobber::JobTest < ActiveSupport::TestCase
  test "as_json should return the correct attributes" do
    job = Factory(:job)

    expected = %w(id type data)
    actual = job.as_json.keys.map(&:to_s).sort

    assert_equal expected.sort, actual
  end
end



class Jobber::JobAcquireTest < ActiveSupport::TestCase
  def setup
    @job = Factory.build(:job)
    @job.acquire!("me")
  end

  test "should set locked_at to Time.now" do
    time = Time.now
    Time.stubs(:now).returns(time)
    assert_equal time.to_i, @job.locked_at.to_i
  end

  test "should set locked_by" do
    assert_equal "me", @job.locked_by
  end

  test "should save the Job" do
    assert !@job.new_record?
  end
end



class Jobber::JobLockedTest < ActiveSupport::TestCase
  def setup
    @job = Factory.stub(:locked_job)
  end

  test "should return true when locked_by is present and locked_at less than 10 minutes ago" do
    @job.stubs(:locked_by).returns("me")
    @job.stubs(:locked_at).returns(9.minutes.ago)

    assert @job.locked?
  end

  test "should return false when locked_by is nil" do
    @job.stubs(:locked_by).returns(nil)
    assert_equal false, @job.locked?
  end

  test "should return false when locked_by id ''" do
    @job.stubs(:locked_by).returns("")
    assert_equal false, @job.locked?
  end

  test "should return false if locked_at is nil" do
    @job.stubs(:locked_at).returns(nil)
    assert_equal false, @job.locked?
  end

  test "should return false if locked_at is more than 10 minutes ago" do
    @job.stubs(:locked_at).returns(11.minutes.ago)
    assert_equal false, @job.locked?
  end
end



class Jobber::JobDoneTest < ActiveSupport::TestCase
  def setup
    @job = Factory(:job)
    @response_processor = mock("processor")
    @response_processor.stubs(:process)
    Jobber::Job.stubs(:processor_for).returns(@response_processor)
  end

  test "should remove the job from the database" do
    @job.done!
    assert_nil Jobber::Job.find_by_id(@job.id)
  end

  test "should get the response processor" do
    Jobber::Job.stubs(:processor_for).returns(@response_processor)
    @job.done!
  end

  test "should call process with the response data to the reponse_processor" do
    response = mock("response")
    @response_processor.expects(:process).with(@job, response).once
    @job.done!(response)
  end
end



class Jobber::JobRegisterProcessorTest < ActiveSupport::TestCase
  class InvalidProcessor; end
  class Processor
    def self.call(result); end
  end

  def register(klass, name = :default)
    Jobber::Job.register_processor name, klass
  end

  test "should register the processor for later retrieval" do
    register Processor, :jobtype

    assert_equal Processor, Jobber::Job.processor_for(:jobtype)
  end

  test "should raise an ArgumentError when the given processor does not respond to :call" do
    assert_raise ArgumentError do
      register InvalidProcessor
    end
  end

  test "should not raise an ArgumentError when the given processor does respond to :call" do
    assert_nothing_raised do
      register Processor
    end
  end

  test "should take a block as processor, too" do
    assert_nothing_raised do
      Jobber::Job.register_processor :default do |job, result|
      end
    end
  end
end



class Jobber::JobProcessorForTest < ActiveSupport::TestCase
  class Processor1; def self.call(result); end; end
  class Processor2; def self.call(result); end; end

  def setup
    Jobber::Job.register_processor(:type1, Processor1)
    Jobber::Job.register_processor(:type2, Processor2)
  end

  test "should return the Processor set for the given job type if one was found" do
    assert_equal Processor1, Jobber::Job.processor_for(:type1)
    assert_equal Processor2, Jobber::Job.processor_for(:type2)
  end

  test "should return Jobber::DefaultProcessor when no suitable Processor was found" do
    assert_equal Jobber::DefaultProcessor, Jobber::Job.processor_for(:other_job)
  end
end



class Jobber::JobGetTest < ActiveSupport::TestCase
  test "should return the first job that is not locked" do
    Factory(:locked_job)
    Factory(:locked_job)
    job = Factory(:job)
    Factory(:locked_job)

    assert_equal job, Jobber::Job.get
  end

  test "locks should expire after 10 minutes" do
    job = Factory(:locked_job, :locked_at => 11.minutes.ago)
    assert_equal job, Jobber::Job.get
  end

  test "should order the jobs by their run_at date (oldest first)" do
    Factory(:job, :run_at => 2.minutes.ago)
    expected = Factory(:job, :run_at => 2.hours.ago)
    Factory(:job, :run_at => 10.minutes.ago)

    assert_equal expected, Jobber::Job.get
  end

  test "should only return jobs with certain types when the types argument is given" do
    job1 = Factory(:job, :type => "encrypt")
    job2 = Factory(:job, :type => "reencrypt")
    job3 = Factory(:job, :type => "encrypt")

    assert_equal job2, Jobber::Job.get(:reencrypt)
    assert_equal job1, Jobber::Job.get(:encrypt)
    assert_equal job1, Jobber::Job.get(:reencrypt, :encrypt)
    assert_equal job1, Jobber::Job.get([:reencrypt, :encrypt])
    assert_equal job2, Jobber::Job.get("reencrypt")
    assert_equal job1, Jobber::Job.get("encrypt")
    assert_equal job1, Jobber::Job.get("reencrypt", "encrypt")
    assert_equal job1, Jobber::Job.get(["reencrypt", "encrypt"])
  end

end
