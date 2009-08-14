module DistLockrun
  class CommandTracker

    def self.run!(cmd)
      @@running ||= {}
      @@running[cmd] = true
    end

    def self.stop!(cmd)
      @@running ||= {}
      @@running.delete(cmd)
    end

    def self.running?(cmd)
      @@running ||= {}
      !!@@running[cmd]
    end
  end
end

    
