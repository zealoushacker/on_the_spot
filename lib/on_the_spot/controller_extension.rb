module OnTheSpot
  module ControllerExtension

    def self.included(base)
      base.extend ClassMethods
    end

    # if this method is called inside a controller, the edit-on-the-spot
    # controller action is added that will allow to edit fields in place
    module ClassMethods
      def can_edit_on_the_spot
        _routes = BizeeBee::Application.routes
        _routes.disable_clear_and_finalize = true
        _routes.clear!
        
        _routes.draw do
          resources self.controller_path do
            collection do
              put :update_attribute_on_the_spot
            end
          end
        end

        BizeeBee::Application.routes_reloader.paths.each { |path| load(path) }

        _routes.finalize!
      ensure
        _routes.disable_clear_and_finalize = false
            
        define_method :update_attribute_on_the_spot do
          klass, field, id = params[:id].split('__')
          select_data = params[:select_array]
          object = klass.camelize.constantize.find(id)
          if object.update_attributes(field => params[:value])
            if select_data.nil?
              render :text => CGI::escapeHTML(object.send(field).to_s)
            else
              parsed_data = JSON.parse(select_data.gsub("'", '"'))
              render :text => parsed_data[object.send(field).to_s]
            end
          else
            render :text => object.errors.full_messages.join("\n"), :status => 422
          end
        end
      end
    end
    
  end
end
