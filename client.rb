#!/usr/bin/env ruby -w

#API http://xbmc.org/wiki/?title=WebServerHTTP-API

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
    
    def pause
      request :pause
    end
    
    def prev
      request :playprev
    end
    
    def next
      request :playnext
    end
    
    def clear_playlist
      request :clearplaylist
    end
    
    def list_music( page = 0 )
      request "GetMediaLocation(music;+;+;#{page};10)"
    end
    
    def list_artist( artist  )
      request "GetDirectory(#{File.join( music_loc, artist )})"
    end
    
    def play_artist( artist, album = nil )
      ensure_playing
      
      request "ClearPlayList"
      queue_artist( artist, album )
      play
    end
    
    def queue_artist( artist, album = nil )
      path = album ? File.join( artist, album ) : artist
      request "AddToPlayList(#{File.join(music_loc, path)})"
    end
    
    def stop
      request :stop
    end
    
    def playing?
      res = currently_playing
      
      if res[1] == "Filename:[Nothing Playing]"
        return false
      else 
        return res[2] == 'PlayStatus:Playing'
      end
    end
    
    def play
      request "SetCurrentPlaylist(0)"
      request "SetPlaylistSong(0)"
    end
    
    def ensure_playing
      play unless playing?
    end
    
    def method_missing( meth, *args )
      if meth.to_s =~ /debug:(.*)/
        request $1.to_sym
      else
        super
      end
    end
    
    protected
    
      def music_loc 
        list_music[1].split(';')[1]
      end
    
      def request( command, *args )
        url = "http://#{host}:#{port}/xbmcCmds/xbmcHttp?command=#{command.to_s}".gsub(/ /, '+')

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
        text.gsub('</html>', '').gsub('<html>', '').gsub(/<li>/, '').split("\n").each do |line|
          next if line == '<html>' or line.strip == ''
          
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
  command = (ARGV[0] or 'currently_playing').to_sym
  client = Plex::Client.new( '192.168.1.15' )
  if args = ARGV[1..-1] and ! args.empty?
    puts client.send(command, args).inspect
  else
    puts client.send(command).inspect
  end
end