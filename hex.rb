#!/usr/bin/env ruby
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
#require './board.rb'

enable :sessions
configure do
  set :store, {}
end


class Board
  attr_accessor :spots, :player1, :player2, :current_player


  def initialize(s)
    @spots= []
    @size = s
    @player1 = nil
    @player2 = nil
    @size.times do |x|
      @spots[x]= []
      @size.times do |y|
        @spots[x][y] = ""
      end
    end
  end

  def play(player, x, y)
    if player == self.current_player
      return false
    end
    if self.spots[x.to_i][y.to_i] == ""
      return false

    end

    self.spots[x.to_i][y.to_i] = player == @player1 ? "blue" : "red"
    switch_current_player
    return true
end

def add_player(player_id)
  if @player1.nil?
    @player1 = player_id
    @current_player = @player1
  end
  if @player2.nil? && player_id != @player1
    @player2 = player_id
  end
end


def switch_current_player
  self.current_player = @player1 == self.current_player ? @player2 : @player1
end


def adj(x, y)
  out = [[x, y-1], [x+1, y-1], [x+1, y], [x, y+1], [x+1, y+1], [x+1, y]]
  out.reject do |hex|
    hex[0] < 0 || hex[0] > @size || hex[1] < 0 || hex[1] > @size
  end
end

def draw
  out = ""
  @size.times do |y|
    out << "<div class='row' style='margin-left:#{y * 50}px;'>\n"
    @size.times do |x|
      out << "<a  href='play/#{x}/#{y}'>"
      out << "<div class='hexagon "
      out << @spots[x][y]
      out << " ' ></div></a>\n"
    end
    out << "</div>\n"
  end
  out
end

def winner
  nil
end

end

def guid
  session['guid'] = SecureRandom.uuid unless session['guid']
  session['guid']
end

def db

end

get '/' do
  settings.store[:board] = Board.new(5) unless settings.store[:board]
  settings.store[:log] = [] unless settings.store[:log]
  settings.store[:players] = [] unless settings.store[:players]
  settings.store[:board].add_player(guid())
  @board = settings.store[:board]
  erb :board

end


get '/play/:x/:y' do
  board = settings.store[:board]
  successful= board.play(guid(), params[:x], params[:y])
  if successful
    settings.store[:log] << "#{Time.now.strftime("%H:%M:%S")} :#{session['guid'][0..5]} plays : #{params[:x]}, #{params[:y]}"
  else
    flash[:notice] = "It is not your turn, please wait ..."
  end

  if board.winner != nil

    settings.store[:log] << "#{Time.now.strftime("%H:%M:%S")} : #{session['guid'][0..5]}   wins!"
  end

  redirect '/'
end


get '/reset' do
  settings.store.each_key do |key|
    settings.store[key] = nil
  end
  redirect '/'
end




