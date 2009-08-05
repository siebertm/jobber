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
    Jobber::JobsController.locker_name(nil)
    Jobber::JobsController.set_scope(nil)
  end

  LOCKER_NAME = "nobody"

  test "I should be able to configure the locker name" do
    Jobber::JobsController.locker_name { LOCKER_NAME }
    job = Factory(:job)

    @controller.stubs(:fetch_job).returns(job)
    job.expects(:acquire!).with(LOCKER_NAME)

    post :create

    assert_got_job(job)
  end

  test "the locker_name should be evaled in controller context" do
    call_context = nil
    Jobber::JobsController.locker_name do
      call_context = self
      "me"
    end

    post :create
    assert_equal @controller, call_context
  end

  test "I should be able to configure a scope to apply to the Jobber::Job.get" do
    expected = Factory(:job, :data => "foo")
    Factory(:job)

    called = false
    Jobber::JobsController.set_scope do
      called = true
      {:conditions => {:data => "foo"}}
    end


    post :create

    assert called
    assert_got_job(expected)
  end

  test "the job scope should evaled in controller context" do
    call_context = nil
    Jobber::JobsController.set_scope do
      call_context = self
      {}
    end

    post :create
    assert_equal @controller, call_context
  end

  def assert_got_job(expected)
    assert_equal expected.id, decode(@response.body)['id']
  end
end


