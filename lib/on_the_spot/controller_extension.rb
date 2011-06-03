module OnTheSpot
  module ControllerExtension

    def self.included(base)
      base.extend ClassMethods
    end

    # if this method is called inside a controller, the edit-on-the-spot
    # controller action is added that will allow to edit fields in place
    module ClassMethods
      def can_edit_on_the_spot
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

        self.send :before_filter, lambda {
          _controller_path = self.controller_path
          _routes = BizeeBee::Application.routes
          if _routes.routes.find { |r| r.path =~ /#{_controller_path}\/update_attribute_on_the_spot/}.nil?
            _routes.disable_clear_and_finalize = true
            _routes.clear!
             
            logger.debug("-1.#{_controller_path}-")

            _routes.draw do
              resources _controller_path do
                collection do
                  put :update_attribute_on_the_spot
                end
              end
            end

            BizeeBee::Application.routes_reloader.paths.each { |path| load(path) }

            _routes.finalize!
            _routes.disable_clear_and_finalize = false
          end
        }
      end
    end
    
  end
end
