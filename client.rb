#!/usr/bin/env ruby -w

require 'rubygems'
require 'net/http'
require 'uri'
require 'open-uri'


module Plex
  class Client
    attr :host
    attr :port
    
    def initialize( host, port = 3000 )
      @host, @port = host, port
    end

    def currently_playing
      request(:getcurrentlyplaying)
    end
    
    protected
      def request( command, *args )
        url = "http://#{host}:#{port}/xbmcCmds/xbmcHttp?command=#{command.to_s}"
        
        begin
          open( url ) {|f| parse_response f.read }
        rescue Errno::ETIMEDOUT => timeout
          STDERR.puts "Unable to communicate with the server at #{host}:#{port}"
          return nil
        end
      end
      
      def parse_response( text )
        response = {}
        # figure out how to really strip tags
        text.gsub(/<\/html>/, '').gsub(/<li>/, '').split("\n").each do |line|
          next if line == '<html>'
          
          puts line
          key, val = line.split(':')
          response[key.downcase.gsub(/[^a-z0-9_-]/, '_').to_sym] = [val].flatten.join(':')
        end
      end
  end
  
  module Commands
    class Base
      
    end
  end
end

if __FILE__ == $0
  client = Plex::Client.new( '192.168.1.15' )
  puts "What's playing: #{client.currently_playing}"
end