class GenerateWeeklySummaryJob < ApplicationJob
  queue_as :default

  retry_on Faraday::Error, wait: :exponentially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(user)
    AiCoachService.new(user).generate_weekly_summary!
  end
end
