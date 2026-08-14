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

  test "show renders activity details and overlay export modal" do
    activity = full_activity.merge(
      "map" => { "summary_polyline" => "_p~iF~ps|U_ulLnnqC_mqNvxq`@" },
      "elapsed_time" => 4000,
      "elev_low" => 120.0,
      "elev_high" => 270.0,
      "average_watts" => 180.0,
      "kilojoules" => 650.0,
      "average_cadence" => 85.0,
      "max_cadence" => 110.0,
      "suffer_score" => 82,
      "device_name" => "Garmin Edge 530",
      "gear_id" => "b123456789",
      "pr_count" => 2,
      "achievement_count" => 3,
      "average_temp" => 18.0,
      "total_photo_count" => 1,
      "photos" => { "primary" => { "urls" => { "600" => "https://example.com/photo.jpg" } } }
    )

    stub_strava_service(activity: activity) do
      get :show, params: { id: activity["id"] }
      assert_response :success
      assert_select "h1", /Morning Ride/
      assert_select "h2", /Export Overlay Graphic/
      assert_select "button[disabled]", text: /Export Overlay Graphic/, count: 0
      assert_select "[data-controller='overlay-generator']"
      assert_select "[data-controller='route-map']"
      assert_select "[data-route-map-polyline-value='_p~iF~ps|U_ulLnnqC_mqNvxq`@']"
      assert_select "button[data-action='overlay-generator#download']", /Download PNG/
      assert_select "button[data-action='overlay-generator#copyToClipboard']", /Copy to Clipboard/
      assert_select ".text-2xl, .text-3xl", /25\.0 km/
      assert_select ".text-2xl, .text-3xl", /1:00:00/
      assert_select ".text-lg.font-bold", /120–270 m/
      assert_select ".text-sm.font-medium", /Garmin Edge 530/
      assert_select ".text-sm.font-medium", /b123456789/
    end
  end

  test "show disables overlay export when no route polyline" do
    activity = full_activity

    stub_strava_service(activity: activity) do
      get :show, params: { id: activity["id"] }
      assert_response :success
      assert_select "button[disabled]", text: /Export Overlay Graphic/
      assert_select ".group-hover\\:opacity-100", /No GPS route data available/
    end
  end

  private

  def full_activity
    {
      "id" => 123,
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
    }
  end

  def stub_strava_activities(activities)
    stub_strava_service(activities: activities) { yield }
  end

  def stub_strava_service(activities: [], activity: nil)
    original_new = StravaService.method(:new)
    StravaService.define_singleton_method(:new) { |_user| FakeStravaService.new(activities, activity) }
    yield
  ensure
    StravaService.singleton_class.send(:define_method, :new) { |user| original_new.call(user) }
  end
end

class FakeStravaService
  def initialize(activities, activity = nil)
    @activities = activities
    @activity = activity
  end

  def recent_activities(days:)
    @activities
  end

  def activity(id)
    @activity || @activities.find { |a| a["id"].to_s == id.to_s }
  end
end
