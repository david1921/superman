class Accounting::RevenueSharingAgreementsController < Accounting::ApplicationController
  
  def index
    @publishing_groups = PublishingGroup.all.sort_by(&:name)
  end
  
end