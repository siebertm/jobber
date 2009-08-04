require File.join(File.dirname(__FILE__), '../../test_helper')

class Jobber::JobsControllerTestWithNoSuitableJobs < ActionController::TestCase
  tests Jobber::JobsController

  def setup
    Jobber::Job.stubs(:get).returns(nil)
    post :create
  end

  test "should return an empty response" do
    assert @response.body.blank?
  end

  test "should return a 200 status code" do
    assert_response :ok
  end
end


class Jobber::JobsControllerTestWithOneSuitableJob < ActionController::TestCase
  tests Jobber::JobsController

  def setup
    @job = Factory(:job)
    Jobber::Job.stubs(:get).returns(@job)
  end

  test "should return the json representation of that job" do
    expected = @job.as_json.stringify_keys

    post :create
    assert_equal expected, decode(@response.body)
  end

  test "should return a 200 status code" do
    post :create
    assert_response :ok
  end

  test "should acquire! the job" do
    @job.expects(:acquire!).with("anonymous")
    post :create
  end

  test "should pass the space-separated skill param to the get method" do
    Jobber::Job.expects(:get).with(["foo", "bar"]).returns(@job)
    post :create, :skill => "foo bar"
  end
end

class Jobber::JobsControllerPutTest < ActionController::TestCase
  tests Jobber::JobsController

  NOT_EXISTING_JOB_ID = '444'
  EXISTING_JOB_ID = '222'

  def setup
    @job = Factory.build(:job)
    @job.stubs(:done!)

    Jobber::Job.stubs(:find).with(EXISTING_JOB_ID).returns(@job)
    Jobber::Job.stubs(:find).with(NOT_EXISTING_JOB_ID).raises(ActiveRecord::RecordNotFound)
  end

  def send_results(id = EXISTING_JOB_ID, result = "some result")
    put :update, {:id => id, :job => { :result => result }}
  end


  test "should respond with 404 if the job was not found" do
    send_results(NOT_EXISTING_JOB_ID)
    assert_response :not_found
  end

  test "should call the job's done! method" do
    @job.expects(:done!)
    send_results
  end

  test "should render nothing" do
    send_results
    assert @response.body.blank?
  end

  test "should respond with 200 OK" do
    send_results
    assert_response :ok
  end

end


class Jobber::ConfiguringJobsControllerTest < ActionController::TestCase
  tests Jobber::JobsController

  def teardown
    Jobber::JobsController.locker(nil)
  end

  test "i should be able to configure the locker name" do
    locker_name = "nobody"

    Jobber::JobsController.locker do
      locker_name
    end

    assert_equal locker_name, @controller.send(:locker)
  end
end


