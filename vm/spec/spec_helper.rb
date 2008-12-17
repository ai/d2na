require File.join(File.dirname(__FILE__), '../lib/d2na-vm')

class RecorderCode < D2NA::Code
  def initialize(&block)
    super(&block)
    @__signals = []
    listen &method(:__dispatch)
  end
  
  def __dispatch(code, signal)
    @__signals << signal
  end
  
  def out
    signals = @__signals
    @__signals = []
    signals
  end
end
