require "test_helper"

class ActivitiesControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
    session[:user_id] = @user.id
  end

  test "index renders dashboard with activities" do
    activities = [
      {
        "id" => 1,
        "name" => "Morning Ride",
        "type" => "Ride",
        "distance" => 25_000.0,
        "moving_time" => 3600,
        "total_elevation_gain" => 150.0,
        "average_speed" => 6.94,
        "max_speed" => 12.5,
        "average_heartrate" => 145.0,
        "max_heartrate" => 175.0,
        "calories" => 800,
        "start_date_local" => 1.day.ago.iso8601
      },
      {
        "id" => 2,
        "name" => "Afternoon Run",
        "type" => "Run",
        "distance" => 5000.0,
        "moving_time" => 1800,
        "total_elevation_gain" => 50.0,
        "start_date_local" => 2.days.ago.iso8601
      }
    ]

    stub_strava_activities(activities) do
      get :index
      assert_response :success
      assert_select "h1", /Welcome back, Ada Lovelace/
      assert_select ".text-3xl", /30\.00/
      assert_select "p.font-semibold", /Morning Ride/
      assert_select ".text-xl", /145 bpm/
      assert_select "a[href=?]", activity_path(1), text: /View details/
    end
  end

  test "index renders empty state when no activities" do
    stub_strava_activities([]) do
      get :index
      assert_response :success
      assert_select "h1", /Welcome back/
      assert_select "h5", /No activities found/
    end
  end

  private

  def stub_strava_activities(activities)
    original_new = StravaService.method(:new)
    StravaService.define_singleton_method(:new) { |_user| FakeStravaService.new(activities) }
    yield
  ensure
    StravaService.singleton_class.send(:define_method, :new) { |user| original_new.call(user) }
  end
end

class FakeStravaService
  def initialize(activities)
    @activities = activities
  end

  def recent_activities(days:)
    @activities
  end
end
