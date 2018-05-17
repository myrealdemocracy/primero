class PotentialMatchesController < ApplicationController
  @model_class = PotentialMatch

  include IndexHelper
  include RecordFilteringPagination
  include RecordActions
  require "will_paginate/array"


  #TODO v1.3: need controller rspec for this
  def index
    authorize! :index, model_class
    @page_name = t("home.view_records")
    @aside = "shared/sidebar_links"
    @associated_users = current_user.managed_user_names
    @filters = record_filter(filter)
    #make sure to get all records when querying for ids to sync down to mobile
    params["page"] = "all" if params["mobile"] && params["ids"]
    @type ||= params[:type] || "tracing_request"
    @match_model_class ||= (@type == 'case' ? 'child' : @type).camelize.constantize

    load_potential_matches #@potential_matches, @case, @tracing_request
    #TODO MATCHING: All set visibility code is written by somone who didn't understand how record ownership works in Primero
    #               We don't need to address this now, but it really needs to be done away with.
    @associated_user_names = users_filter
    set_visibility(@potential_matches, @associated_user_names)

    @potential_matches = apply_filter_to_records(@potential_matches, @filters)
    @grouped_potential_matches = PotentialMatch.group_match_records(@potential_matches, @type)

    #TODO MATCHING: Pagination of grouped record is just broken.
    #               Luckily for this we will just display matches for an individual TR/case
    @per_page = per_page
    @grouped_potential_matches = @grouped_potential_matches.paginate(:page => page, :per_page => per_page)
    @total_records = @grouped_potential_matches.total_entries

    respond_to do |format|
      format.html
      unless params[:password]
        format.json do
          render :json => PotentialMatch.format_list_for_json(@grouped_potential_matches, @type)
        end
      end
      unless params[:format].nil? || params[:format] == :json
        if @grouped_potential_matches.blank?
          flash[:notice] = t("exports.no_records")
          redirect_to :action => :index and return
        end
      end
      respond_to_export format, @potential_matches
    end
  end

  def load_potential_matches
    @potential_matches = []
    #TODO MATCHING: This is a temporary hack, get rid of this
    @total_records = 0
    if @match_model_class == Child
      load_case_matches
    else
      load_tracing_request_matches
    end
    #TODO MATCHING: Do we need this? are the search results already in correct order?
    @potential_matches = @potential_matches.sort_by{|pm| pm.average_rating}.reverse
  end


  def load_tracing_request_matches
    if params[:match].present?
      tracing_request_id = params[:match].split("::").first
      @subform_id = params[:match].split("::").last
      @tracing_request = TracingRequest.get(tracing_request_id) if tracing_request_id.present?
      if @tracing_request.present?
        @potential_matches = @tracing_request.matching_cases(@subform_id)
        #TODO MATCHING: This is a temporary hack, get rid of this
        @total_records = 1
      end
    end
  end

  def load_case_matches
    if params[:match].present?
      case_id = params[:match]
      @case = Child.get(case_id) if case_id.present?
      #if @case.present?
        #TODO MATCHING: Implement on-demand case matches for tracing requests
        #@potential_matches = @case.matching_tracing_requests
      #end
    end
  end

  def record_filter(filter)
    filter ||= {}
    filter["status"] ||= {:type => "single", :value => "#{PotentialMatch::POTENTIAL}"}
    return filter
  end

  private

  def set_visibility(records=[], associated_user_names)
    records.each{|r| r.set_visible(associated_user_names, @type)}
  end
end
