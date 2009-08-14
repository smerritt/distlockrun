module DistLockrun
  module Client

    KEEPALIVE_INTERVAL = 5   # seconds
    
    def self.command=(c)
      @@command = c
    end

    def post_init
      @buffer = ''
      send_data ("run " + @@command.join(' ') + "\n")
    end
    
    def receive_data(data)
      @buffer << data
      if @buffer =~ /^yes\n/
        @buffer = ''
        puts "got the lock"
        start_command
      elsif @buffer =~ /^no\n/
        @buffer = ''
        puts "oh well, better luck next time"
        exit 0
      end
    end

    def start_command
      @command_running = true
      trap('CHLD', proc { @command_running = false})

      pid = fork
      if pid
        @pid = pid
      else
        puts "going to exec #{@@command.inspect}"
        exec *@@command
      end

      status_update
    end
    
    def status_update
      if @command_running
        send_data "keepalive\n"
      else
        exit 0
      end
      
      EventMachine::Timer.new(KEEPALIVE_INTERVAL) do
        status_update
      end
    end

  end
end

