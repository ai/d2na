require File.join(File.dirname(__FILE__), '../lib/d2na-vm')

class RecorderCode < D2NA::Code
  def __dispatch(code, signal)
    @__signals << signal
  end
  
  def out
    signals = @__signals
    @__signals = []
    signals
  end
  
  def reset!
    super
    @__signals = []
    listen &method(:__dispatch)
  end
end
