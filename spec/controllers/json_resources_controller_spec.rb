require 'spec_helper'

class Tester < ActiveRecord::Base
  attr_accessible :name, :id
end

class TesterController < JsonResourcesController
end

def mock_check_object_model
  check_object = mock_model(Tester)
  Tester.should_receive(:new).with(no_args()).and_return(check_object)
  check_object.should_receive(:attributes).and_return({ "name" => nil, "id" => nil })
end

describe TesterController do
  
  controller(TesterController) do
  end
  
  before(:each) do
    Kernel.should_receive(:const_get).at_most(25).times.and_return(Tester)
  end        
  
  describe "#create" do
    
    context "When a tester does not exist" do
      
      context "and valid attributes are given" do
        it "creates a new tester" do
          input = { "name" => "Test Account", "id" => 1 }
          expected = { "name" => "Test Account","id" => 1 }
          @controller.should_receive(:url_for).twice.with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/testers/1')
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/testers/')
          
          mock_check_object_model
          
          tester = mock_model(Tester)
          Tester.should_receive(:new).with(input).and_return(tester)
          tester.should_receive(:save).and_return(true)
          tester.should_receive(:testers).and_return(nil)
          tester.should_receive(:id).and_return(1)
          tester.should_receive(:attributes).and_return(expected)

          json_post_response_should_be(:create, input, expected, 201)
        end
      end
      
      context "and valid attributes with extra attributes are given" do
        it "returns 201 with the matching representation in json, the extra attributes are ignored" do
          input = { "name" => "New Name", "id" => 1, "this_is_an_attribute_that_doesn't_exiti_on_the_model" => 42 }
          expected = {"name" => "New Name", "id" => 1, "self" => "http://test.host/testers/1", "index" => "http://test.host/testers/"}

          mock_check_object_model
          
          @controller.should_receive(:url_for).twice.with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/testers/1')
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/testers/')         
          object_to_be_created = mock_model(Tester)
          Tester.should_receive(:new).with( { "name" => "New Name", "id" => 1}).and_return(object_to_be_created)
          object_to_be_created.should_receive(:save).and_return(true)
          object_to_be_created.should_receive(:testers).and_return(nil)
          object_to_be_created.should_receive(:id).and_return(1)
          object_to_be_created.should_receive(:attributes).and_return({ "name" => "New Name", "id" => 1})
          json_post_response_should_be(:create, input, expected, 201)
          response.headers["Location"].should == 'http://test.host/testers/1'
   	    end
      end
  
      context "and invalid attributes are given" do
        it "returns 422" do
          input = { "id" => 1}
          expected = {"error" => {"type" => "InvalidResourceFields",
                                  "message" => "Some fields couldn't be validated.",
                                  "detail" => {"name" => ["can't be blank"]}}}
                                  
          mock_check_object_model
          
          tester = mock_model(Tester)
          Tester.should_receive(:new).with(input).and_return(tester)
          tester.should_receive(:save).and_return(false)
          tester.stub_chain(:errors, :messages).and_return({ :name => ["can't be blank"] })
          post_json :create, input
          error_response_should_be(422, "InvalidResourceFields", "Some fields couldn't be validated.", {"name" => ["can't be blank"]})
        end
      end
      
      context "and invalid JSON is given" do
        it "returns 415" do
          request.env['RAW_POST_DATA'] = "abc"
          post :create
          error_response_should_be(415, "InvalidJSON", "Invalid JSON.", "abc")
        end
      end
      
    end #context "When a tester does not exist"
    
    context "when a controller sets the scope" do
      it "should automatically set the scope variable" #new should be sent the scope
    end
      
  end #describe "#create"
  
  describe "#index" do
    context "When a tester does not exist" do
            
      it "returns an empty list" do
        @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/testers/')
        Tester.stub_chain(:where, :all).and_return([])
        get :index, :format => :json
        response_should_be({ :testers => [], :self => 'http://test.host/testers/' }, 200)
      end
    end
    
    context "When two testers exist" do
     it "returns a list with two testers" do
       expected = { 
                    :testers => [ 
                                   { :name => "Tester 1", :id => 1, :self => 'http://test.host/testers/1', :index => 'http://test.host/testers/' }, 
                                   { :name => "Tester 2", :id => 2, :self => 'http://test.host/testers/2', :index => 'http://test.host/testers/' }  
                                 ], 
                    :self => 'http://test.host/testers/'
                  }
       @controller.should_receive(:url_for).with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/testers/1')
       @controller.should_receive(:url_for).with({:controller => "testers", :action => "show", :id => "2"}).and_return('http://test.host/testers/2')
       @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).exactly(3).times.and_return('http://test.host/testers/')
       tester1 = mock_model(Tester)
       tester2 = mock_model(Tester)
       tester1.should_receive(:attributes).and_return({ "name" => "Tester 1", "id" => 1})
       tester2.should_receive(:attributes).and_return({ "name" => "Tester 2", "id" => 2})
       Tester.stub_chain(:where, :all).and_return([tester1, tester2])
       get :index, :format => :json
       response_should_be(expected, 200)
     end
   end        
  end
  
  describe "#show" do
    context "When a tester does not exist" do
      it "returns 404 with no matching account" do
        Tester.stub_chain(:where, :find).and_raise(ActiveRecord::RecordNotFound)
        get :show, :id => 1, :format => :json
        error_response_should_be(404, "ResourceNotFound", "Resource not found.")
      end
    end

    context "When one tester exists" do
      it "returns proper json when tester with that id exists" do
        expected = { :name => "Tester 1", "id" => 1 }
        @controller.should_receive(:url_for).with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/testers/1')
        @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/testers/')
        tester = mock_model(Tester)
        tester.should_receive(:attributes).and_return(expected)
        tester.should_receive(:testers).and_return(nil)
        Tester.stub_chain(:where, :find).and_return(tester)
        get :show, :id => 1, :format => :json
        response_should_be(expected, 200)    
      end      
    end # context "When one tester exists"
  end # describe "#show"
    
  describe "#update" do
    context "When a tester does not exist" do
      it "returns 404 with no matching account" do
        attributes = { :name => "New Name" }
        tester = mock_model(Tester)
        Tester.stub_chain(:where, :find).and_raise(ActiveRecord::RecordNotFound)
        put :update, :id => 1, :tester => attributes, :format => :json
        error_response_should_be(404, "ResourceNotFound", "Resource not found.")
      end
    end
    
    context "When a tester does exist" do
      context "and valid attributes are given" do
        it "returns 200 with the matching representation in json" do
          attributes = { "name" => "New Name", "id" => 1 }
          tester = mock_model(Tester)
          tester.should_receive(:attributes).twice.and_return(attributes)
          tester.should_receive(:testers).and_return(nil)
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/testers/1')
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/testers/')
          
          Tester.stub_chain(:where, :find).and_return(tester)
          tester.should_receive(:update_attributes).with(attributes).and_return(true)
          put_json(:update, 1, attributes)
          response_should_be(attributes.merge!(:self => "http://test.host/testers/1", :index => "http://test.host/testers/"), 200)
        end
      end
      
     context "and valid attributes with extra attributes are given" do
        it "returns 200 with the matching representation in json, the extra attributes are ignored" do
          attributes = { "name" => "New Name", "id" => 1, "this_is_an_attribute_that_doesn't_exiti_on_the_model" => 42 }
          tester = mock_model(Tester)
          tester.should_receive(:attributes).twice.and_return({ "name" => "New Name", "id" => 1})
          tester.should_receive(:testers).and_return(nil)
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/testers/1')
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/testers/')
          
          Tester.stub_chain(:where, :find).and_return(tester)
          tester.should_receive(:update_attributes).with({"name" => "New Name", "id" => 1}).and_return(true)
          put_json(:update, 1, attributes)
          response_should_be({"name" => "New Name", "id" => 1, "self" => "http://test.host/testers/1", "index" => "http://test.host/testers/"}, 200)
	      end
      end
      
      context "and invalid attributes are given" do
        it "returns 422" do
          #try to put a non-numeric to a numeric
          attributes = { "name" => "New Name", "id" => 1, "favorite_number" => "PSYYYCH! THIS IS NOT A NUMBER" }
          tester = mock_model(Tester)
          Tester.stub_chain(:where, :find).and_return(tester)
          tester.should_receive(:attributes).and_return({ "name" => "New Name", "id" => 1, "favorite_number" => 42 })
          tester.should_receive(:update_attributes).with(attributes).and_return(false)
          tester.stub_chain(:errors, :messages).and_return({"favorte_number" => ["is not a number"]})
          put_json(:update, 1, attributes)
          error_response_should_be(422, "InvalidResourceFields", "Some fields couldn't be validated.", { :favorte_number => ["is not a number"] })
        end
      end
      
      context "and partial attributes are given" do
        it "returns 422" do
          attributes = { "name" => "New Name" }
          tester = mock_model(Tester)
          tester.should_receive(:attributes).and_return({ "name" => "New Name", "id" => 1 })
          Tester.stub_chain(:where, :find).and_return(tester)
          put_json(:update, 1, attributes)
          error_response_should_be(422, "InvalidResourceFields", "Some fields couldn't be validated.", [{ :id => "must be present" }])
      	end
      end
      
    end # context "When a tester does exist"
  end # describe "#update"
  
  describe "#destroy" do
    context "When a tester does not exist" do
      it "returns 404 with no matching account" do
        tester = mock_model(Tester)
        Tester.stub_chain(:where, :find).and_raise(ActiveRecord::RecordNotFound)
        delete :destroy, :id => 50
        error_response_should_be(404, "ResourceNotFound", "Resource not found.")
      end
    end
    
    context "When a tester does exist" do
      it "gets deleted and returns 204" do
        tester = mock_model(Tester)
        Tester.stub_chain(:where, :find).and_return(tester)
        tester.should_receive(:destroy).and_return(true)
        delete :destroy, :id => 1
        response.status.should == 204
      end
    end
  end # describe "#destroy"
  
  describe "render_json method" do
    context "When render_json gets something that isn't hashable" do
      it "returns 500 with the message 'Could not render JSON.'" do
        non_json = 'hey this isn\'t json!'
        expected = { :name => "Tester 1", "id" => 1 }
        tester = mock_model(Tester)
        Tester.stub_chain(:where, :find).and_return(non_json)
        get :show, :id => 1, :format => :json
        error_response_should_be(500, "CouldNotRenderJSON", "Could not render JSON")
      end
    end
  end
  
  describe "Controller with attribute exceptions" do
  
    controller(TesterController) do
      def set_attributes
        attributes :all, :except => [:name]
      end
    end
  
    context "#show" do
      context "and in the representation all attributes are shown except one" do
        it "returns the representation with all attributes except that one" do
          expected = { "id" => 1 }
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/tester/1')
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/tester/')
          tester = mock_model(Tester)
          tester.should_receive(:attributes).and_return(expected.merge("name" => "Tester 1"))
          tester.should_receive(:testers).and_return(nil)
          Tester.stub_chain(:where, :find).and_return(tester)
          get :show, :id => 1, :format => :json
          response_should_be(expected.merge("self" => 'http://test.host/tester/1', "index" => 'http://test.host/tester/'), 200)
        end    
      end
    
      controller(TesterController) do
        def set_attributes
          attributes :none, :except => [:name]
        end
      end
    
      context "and in the representation none of the attributes are shown except one" do
        it "returns the representation with none of the attributes except that one" do
          expected = { "name" => "Tester 1" }
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "show", :id => "1"}).and_return('http://test.host/tester/1')
          @controller.should_receive(:url_for).with({:controller => "testers", :action => "index"}).and_return('http://test.host/tester/')
          tester = mock_model(Tester)
          tester.should_receive(:attributes).and_return({ "id" => 1 }.merge(expected))
          tester.should_receive(:testers).and_return(nil)
          Tester.stub_chain(:where, :find).and_return(tester)
          get :show, :id => 1, :format => :json
          response_should_be(expected, 200)
        end
      end
    end
  end # describe "Controller with attribute exceptions"
  
    describe "Controller Action Enablement and Disablement" do

      context "and all actions are enabled except one" do
        controller(TesterController) do
          def set_actions
            actions :all, :except => [:destroy]
          end
        end
        context "when a resource exists" do
          it "returns 405 for the disabled action" do
            tester = mock_model(Tester)
            Tester.stub_chain(:where, :find).and_return(tester)
            delete :destroy, :id => 1
            error_response_should_be(405, "MethodNotImplemented", "Method not implemented.", "DELETE")
          end
        end

        context "when a resource doesn't exist" do
          it "returns a 404" do
            Tester.stub_chain(:where, :find).and_raise(ActiveRecord::RecordNotFound)
            delete :destroy, :id => 1
            error_response_should_be(404, "ResourceNotFound", "Resource not found.")
          end
        end
      end # context "and all actions are enabled except one"

      context "When none of the actions are enabled except one" do
        controller(TesterController) do
          def set_actions
            actions :none, :except => [:create]
          end
        end
        context "when a resource exists" do
          it "returns 405 for all disabled actions" do
            tester = mock_model(Tester)
            Tester.stub_chain(:where, :find).and_return(tester)
            get :show, :id => 1
            error_response_should_be(405, "MethodNotImplemented", "Method not implemented.", "GET")
          end
        end 
      end # context "When none of the actions are enabled except one"
    end # describe "Controller Action Enablement and Disablement"    
  end



  # class ModelOne < ActiveModel
  #   belongs_to :model_two
  # end
  # 
  # class ModelTwo < ActiveModel
  #   has_one :model_one
  # end
  # 
  # 
  #   describe "hypermedia test or something" do
  #     controller(TesterController) do
  #     end
  # 
  #     it "tell us something" do
  #       get :show, :id => 1
  #       response.body should_be ''
  #     end      
  #     
  #   end


  #end