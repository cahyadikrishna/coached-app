class WeeklySummariesController < ApplicationController
  def index
    @weekly_summaries = current_user.weekly_summaries.order(created_at: :desc)
  end

  def create
    GenerateWeeklySummaryJob.perform_later(current_user)
    redirect_to weekly_summaries_path, notice: "AI Coach is generating your summary..."
  end
end
