module Windsor
  class JsonResourcesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, :with => :resource_not_found
    rescue_from JSON::ParserError, :with => :unsupported_media_type

    before_filter :get_resource, :except => [:index, :create]
    before_filter :scope, :set_attributes, :check_implemented

    attr_accessor :exceptional_attributes
    attr_accessor :attributes_all_or_none

    def index
      @max_page_size = 100 unless @max_page_size
      if params[:page].nil?
        current_page_index = 0
        offset = 0
      else
        current_page_index = params[:page].to_i - 1
        offset = @max_page_size * current_page_index  
      end
      items = model_class.where(scope).limit(@max_page_size).offset(offset).all
      total_items = model_class.count

      object = { 
        get_controller_name => items, 
        :pagination => get_pagination_object(total_items, current_page_index)
      }
      render_json object
    end

    def create
      request_body = JSON.parse(request.body.read)   
      existing_attributes = enabled_attributes(hashity_hash(model_class.new)).map { |item| item.to_s }
      request_body = prune_extra_attributes(request_body, existing_attributes)

      model_object = model_class.new(request_body.merge(scope))
      if model_object.save
        headers["Location"] = get_self_link({"id" => model_object.id})
        render_json model_object, :created
      else
        render_error 422, "InvalidResourceFields", "Some fields couldn't be validated.", model_object.errors.messages
      end
    end

    def show
      render_json @model_object
    end

    def update    
      request_body = JSON.parse(request.body.read)    
      existing_attributes = enabled_attributes(hashity_hash(@model_object)).map { |item| item.to_s }
      request_body = prune_extra_attributes(request_body, existing_attributes)

      # Checks that there is an incoming attribute for every existing attribute (i.e. no partial updates)
      missing_attributes = []
      existing_attributes.each do |existing_attribute, existing_value|
        unless request_body.include?(existing_attribute)
          missing_attributes << existing_attribute
        end
      end

      unless missing_attributes.empty?
        errors = missing_attributes.map { |missing_attribute| { missing_attribute => "must be present" } }
        render_error 422, "InvalidResourceFields", "Some fields couldn't be validated.", errors
        return
      end

      # Compare the existing attributes and the passed-in attributes and remove any passed-in attributes with
      # a value identical to the corresponding existing attribute. This is necessary because update_attributes
      # will error out when trying to update an existing attribute with the same value, if that attribute has a
      # uniqueness validation on it. 
      existing_attributes.each do |existing_attribute, existing_value|
        if request_body[existing_attribute] == existing_value
          request_body.delete existing_attribute
        end
      end

      if @model_object.update_attributes(request_body)
        render_json @model_object
      else
        render_error 422, "InvalidResourceFields", "Some fields couldn't be validated.", @model_object.errors.messages
      end
    end

    def destroy
      @model_object.destroy
      render :nothing => true, :status => 204
    end

    def to_representation(object)
      return object
    end

    # Called before every action, if you want to set the attributes of the representation 
    # redefine this function in your controller with a call to attributes and your paramaters.
    # Example:
    # def set_attributes
    #  attributes :all, :except => [:name]
    # end
    def set_attributes
      attributes :all
    end

    def attributes(all_or_none, exceptional_attributes = { :except => [] })
      @attributes_all_or_none = all_or_none
      @exceptional_attributes = exceptional_attributes[:except].map! { |ex_attr| ex_attr.to_sym }
    end

    def enabled_attributes(object_hash)
      @exceptional_attributes = Array(@exceptional_attributes)
      raise ArgumentError unless [:all, :none].include?(@attributes_all_or_none)

      if @attributes_all_or_none == :all
        keys = object_hash.keys 
        #keys.map! { |key| key.to_sym }
        keys - @exceptional_attributes.map { |enabled_attr| enabled_attr.to_s }
      else
        @exceptional_attributes.map { |enabled_attr| enabled_attr.to_s }
      end
    end

    # Called before every action, if you want to disable certain actions redefine 
    # this function in your controller with a call to actions and your paramaters.
    # Example:
    # def set_actions
    #  actions :all, :except => [:destroy]
    # end
    def set_actions
      actions :all
    end

    def actions(all_or_none, exceptional_actions = { :except => [] })
      @actions_all_or_none = all_or_none
      @exceptional_actions = exceptional_actions[:except]
    end

    def enabled_actions
      @actions_all_or_none ||= :all
      @exceptional_actions ||= []
      @exceptional_actions = Array(@exceptional_actions)
      raise ArgumentError unless [:all, :none].include?(@actions_all_or_none)

      if @actions_all_or_none == :all
        [:index, :show, :create, :update, :destroy] - @exceptional_actions
      else
        @exceptional_actions
      end
    end

    def get_self_link(object_hash)
      url_conditions = { :controller => get_controller_name, :action => "index" }
      url_conditions.merge!(:action => "show", :id => object_hash["id"].to_s) unless object_hash["id"].nil?
      url_for(url_conditions)
    end

    def get_controller_name
      model_class.name.underscore.pluralize
    end

    private

      def get_pagination_object(total_items, current_page_index)
        total_pages = (total_items.to_f / @max_page_size).ceil
        total_pages = 1 if total_pages == 0 # Collections with no items in them still have 1 page.
        last_page_index = total_pages - 1
        query_parameters = request.query_parameters
        pagination = {
          :total_items => total_items, 
          :max_page_size => @max_page_size,
          :first => page_link(1),
          :last => page_link(total_pages.to_s)
        }
        unless current_page_index == last_page_index
          pagination[:next] = page_link((current_page_index + 2))
        end
        if current_page_index >= 1
          pagination[:previous] = page_link(current_page_index)
        end      
        return pagination
      end

      def page_link(page_number)
        query_parameters = request.query_parameters
        base_url = request.base_url + request.path
        query_parameters[:page] = page_number
        return base_url + "?" + query_parameters.to_query
      end        

      # Removes extra attributes passed in. Extra attributes is defined as attributes not sent in a GET.
      def prune_extra_attributes(request_body, existing_attributes)    
        request_body.each do |request_attribute, request_value|
          request_body.delete request_attribute unless existing_attributes.include?(request_attribute)
        end
        return request_body
      end

      def model_class
        Kernel.const_get(self.controller_name.singularize.camelize )
      end

      def get_resource
        @model_object = model_class.where(scope).find(params[:id])
      end      

      def check_implemented
        set_actions
        unless enabled_actions.include?(params[:action].to_sym)
          render_error(405, "MethodNotImplemented", "Method not implemented.", request.method.to_s.upcase)
        end
      end

      def scope
        {}
      end

      def prepare_representation(object)
        object.merge!(:self => get_self_link(object))
        attributes = enabled_attributes(object)
        object.each do |key, value|
          object.delete key unless attributes.include?(key)
        end
        to_representation(object)
      end

      def hashity_hash(item)
        begin
          return item.attributes
        rescue NoMethodError
          begin
            return item.to_hash
          rescue NoMethodError
            raise ArgumentError, "Your object could not be converted to a hash."
          end
        end
      end

      def render_json(object, status = 200)
        begin
          list_name = get_controller_name
          if !object[list_name].nil? && object[list_name].is_a?(Array)
            object[list_name].map! do |item|
              prepare_representation(hashity_hash(item))
            end
            object[:self] = get_self_link(object)
          else
            object = prepare_representation(hashity_hash(object))
          end
          render :json => object, :status => status
        rescue ArgumentError
          if Rails.env.production? || Rails.env.test?
            render_error(500, 'CouldNotRenderJSON', 'Could not render JSON')
          else
            render_error(500, 'CouldNotRenderJSON', 'Could not render JSON', object.inspect)
          end
        end
      end

      def render_error(status, type, message = "", detail = {})
        raise ArgumentError unless status && type
        raise ArgumentError unless message.is_a?(String)
        render :json => { :error => { :type => type.to_s, :message => message, :detail => detail } }, :status => status
      end


      def resource_not_found
        render_error(404, "ResourceNotFound", "Resource not found.")
      end

      def unsupported_media_type
        render_error(415, "InvalidJSON", "Invalid JSON.", request.body.read)
      end
  end
end
