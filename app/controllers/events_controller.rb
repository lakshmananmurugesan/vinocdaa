class EventsController < ApplicationController
before_filter :set_event, only: [:show, :edit, :update, :destroy]
before_action :authenticate_user!, only: [:show, :new]

	def index
    if params[:utf8].present?

     query ||= []
     query << "is_published = true"
     query << "event_type = '#{params[:event_type]}'" if params[:event_type].present?
     query << "country = '#{params[:country]}'" if params[:country].present?
     query << "state = '#{params[:state]}'" if params[:state].present?
     query << "district = '#{params[:city]}'" if params[:city].present?
     query << "event_details.start_date >= '#{Date.parse(params[:search_date]).beginning_of_day}'" if params[:search_date].present?
     query << "event_departments.id IN (#{params[:department].join(",")})" if params[:department].present?

     @events = Event.joins(:event_departments, :event_college_banner, :event_detail).where(query.join(" AND ")).paginate(:page => params[:page], :per_page => 4).order("event_details.start_date ASC").select("event_name, study_place, country, state, district, event_type, event_details.start_date as start_date, event_details.end_date as end_date, event_college_banners.id as college_banner_id, events.id as id").uniq
     # binding.pry
    else
     @events = Event.joins(:event_departments, :event_college_banner, :event_detail).where(is_published: true).paginate(:page => params[:page], :per_page => 4).order("event_details.start_date ASC").select("event_name, study_place, country, state, district, event_type, event_details.start_date as start_date, event_details.end_date as end_date, event_college_banners.id as college_banner_id, events.id as id").uniq
     # binding.pry
    end

   if params[:event_type].present?
     @result_msg = "Search Results for #{params[:event_type]}" 
   else
    @result_msg = "Search Results for Events" 
   end

	end

	def new
		@event = Event.new
		@event.build_event_detail
		@event.build_event_url
    @event.build_event_accomodation
    @event.build_event_banner
    @event.build_event_college_banner
    @event.build_event_broucher
	end

	def create
		@event = Event.new(event_params)
  	if @event.save
  		redirect_to @event, flash: { success: "Successfully created event" }
  	else
  		render 'new'
  	end
	end

	def show
    event_id = @event.id
    user_id = current_user.id
    event_going = EventGoing.find_by(event_id: event_id, user_id: user_id)
    EventService.new().event_going_reach_count(event_going, event_id, user_id)
	end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to @event
    else
      render 'edit'
    end
  end


  def destroy
    @event.destroy
    redirect_to :back, flash: { success: "The event has been destroyed successfully!" }
  end

  def welcome
  end

  def states
    render json: CS.states(params[:country]).to_json
  end

  def cities
    render json: CS.cities(params[:state], params[:country]).to_json
  end

  def departments
    render json: EventDepartment.where(stream_id: params[:stream_id]).to_json
  end

  def get_event_results
    @results = Event.where(country: params[:query]).paginate(:page => params[:page], :per_page => 2).order("created_at DESC")
    render json: @results.to_json
  end

  def event_subscription
    if current_user
      @subscribe = EventSubscription.create(email_id: params[:subscribe_email], user_id: current_user.id)
      if @subscribe.id.present?
        redirect_to :back, flash: { success: "Successfully, You are subscribed !" }
      else
        redirect_to :back, flash: { success: "You are already subscribed !" }
      end
    end
  end

  def event_going
   event_id = params[:event_id].to_i
   user_id = current_user.id
   event_going = EventGoing.find_by(event_id: event_id, user_id: user_id)
   redirect_to :back, flash: { success: EventService.new().going_and_may_be_count(event_going, params) }
  end

  def campus_ambassador
    render layout: false
  end

	private

  def event_params
		params.require(:event).permit(:first_name, :last_name, :email, :phone_no, 
			:event_name, :event_type, :study_place, :dept_stream, :country, :state, :district, :zip,
			:location, :event_detail_id, :id, 
			event_detail_attributes: [:start_date, :end_date,
			 :event_description, :sub_events, :workshops, :paper_presentation_topics, :conference_topics, :reg_start_date, :reg_end_date, :reg_fee, :id],
			event_department_ids: [],
			event_contact_details_attributes: [:designation, :name, :email, :phone_no, :general_support, :id, :_destroy],
			event_guest_details_attributes: [:name, :designation, :company, :delegation, :id, :_destroy],
			event_url_attributes: [:web_link, :registration_link, :college_link, :facebook_link, :twitter_link, :youtube_link, :apps_link, :id],
      event_extra_ids: [],
      event_accomodation_attributes: [:accomodation, :id],
      event_banner_attributes: [:banner, :id],
      event_college_banner_attributes: [:college_banner, :id],
      event_broucher_attributes: [:broucher, :id],
      event_sponsors_attributes: [:sponsor, :id, :_destroy]
			).tap do |attributes|
				attributes[:event_detail_attributes][:start_date] = parse_time(attributes[:event_detail_attributes][:start_date]) if attributes[:event_detail_attributes].present?
				attributes[:event_detail_attributes][:end_date] = parse_time(attributes[:event_detail_attributes][:end_date]) if attributes[:event_detail_attributes].present?
				attributes[:event_detail_attributes][:reg_start_date] = parse_time(attributes[:event_detail_attributes][:reg_start_date]) if attributes[:event_detail_attributes].present?
				attributes[:event_detail_attributes][:reg_end_date] = parse_time(attributes[:event_detail_attributes][:reg_end_date]) if attributes[:event_detail_attributes].present?
		end
  end

  def parse_time time
    Time.zone.parse(DateTime.strptime(time,"%m/%d/%Y %I:%M %P").to_s) if time.present?
  end

  def set_event
  	@event = Event.find(params[:id])
  end

end