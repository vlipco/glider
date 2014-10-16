# Monkey Patch a class to allow access to the @decisions variable
class AWS::SimpleWorkflow::DecisionTask; attr_reader :decisions; end

class Glider::Component

    attr_reader :completed_event, :control

    class << self # all the following are class methods

        def workflows
          @workflows ||= []
        end
        
        


        

    end # class methods
end # class definition