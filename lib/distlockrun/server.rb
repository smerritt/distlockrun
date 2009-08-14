module DistLockrun

  module Server
    MAX_BUFFER_SIZE = 65536     # bigger than any command line I know of

    def debug_puts(str)
      # just funnel everything through here so it's easy to turn off
      puts str
    end

    def extract_message!
      # XXX hm I smell a dispatch table here
      if @buffer =~ /^run ([^\n]+)\n/
        cmd = $1
        @buffer = ''
        [:run, cmd]
      elsif @buffer =~ /^stop\n/
        @buffer = ''
        [:stop]
      elsif @buffer =~ /^keepalive\n/
        [:keepalive]
      else
        nil
      end
    end

    def post_init
      debug_puts "got connection"
      @buffer = ""
      set_comm_inactivity_timeout(60)
    end

    def receive_data(data)
      debug_puts "received data #{data}"
      @buffer << data
      @buffer = '' if @buffer.length > MAX_BUFFER_SIZE
      message, *data = extract_message!
      return unless message

      method = "handle_#{message.to_s}".to_sym
      if respond_to?(method)
        send(method, *data)
      else
        raise "I parsed a message #{message} but I can't handle it"
      end
    end

    def handle_run(cmd)
      if @cmd
        send_data "you're already running a command, bozo\n"
        close_connection_after_writing
      elsif CommandTracker.running?(cmd)
        debug_puts "not letting them run #{cmd}"
        send_data "no\n"
        close_connection_after_writing
      else
        debug_puts "letting them run #{cmd}"
        @cmd = cmd
        CommandTracker.run!(cmd)
        send_data "yes\n"
      end
    end

    def handle_stop
      CommandTracker.stop!(@cmd)
      send_data "goodbye\n"
      close_connection_after_writing
    end

    def handle_keepalive
      send_data "ack\n"
    end

    def unbind
      CommandTracker.stop!(@cmd) if @cmd
    end
    
  end

end
