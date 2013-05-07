#!/usr/bin/env ruby
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
#require './board.rb'

enable :sessions
configure do
  set :store, {}
end


class Player
  attr_accessor :guid, :color, :player_num


  def initialize(options)
    @guid = options[:guid]
    @color = options[:color]
    @player_num = options[:player_num]
  end

  def ==(player)
    player != nil && @guid == player.guid
  end

  def to_s
    "#<Player guid=#{self.g}, color=#{@color}, player_num=#{@player_num}>"
  end

  def g
    guid[0, 6]
  end

end

class Board
  attr_accessor :spots, :player1, :player2, :current_player
  attr_reader :size


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

  def player(guid)
    if @player1 != nil && guid == @player1.guid
      return @player1
    end
    if @player2 != nil && guid == @player2.guid
      return @player2
    end

    Player.new(:guid => guid, :color => "black", :player_num => 3)

  end

  def play(player, x, y)

    if player != self.current_player
      return "It is not your turn"
    end
    if self.spots[x.to_i][y.to_i] != ""
      return "This Hex is already taken"
    end

    self.spots[x.to_i][y.to_i] = current_player.color
    switch_current_player
    nil
  end

  def add_player(player_id)
    if @player1.nil?
      @player1 = Player.new(:guid => player_id, :color => "red", :player_num => 1)
      @current_player = @player1
    end
    if @player2.nil? && player_id != @player1.guid
      @player2 = Player.new(:guid => player_id, :color => "blue", :player_num => 2)
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

  def draw(s=50)
    out = ""
    @size.times do |y|
      out << "<div class='row' style='margin-left:#{y * s /2}px;'>\n"
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

  def winner?
   false


  end

  def turn
    i =0
    @size.times do |x|
      @size.times do |y|
        if @spots[x][y] != ""
          i= i+1
        end
      end
    end
    i
  end
end

def guid
  session['guid'] = SecureRandom.uuid unless session['guid']
  session['guid']
end

def me
  db[:board].player(guid)
end

def db
  settings.store
end

get '/' do
  size = params[:size].to_i ||= 12
  db[:board] = Board.new(size) unless db[:board]
  db[:log] = [] unless db[:log]
  db[:players] = [] unless db[:players]
  db[:board].add_player(guid())
  @board = db[:board]

  if   @board.player2.nil?
    erb :waiting_player
  else

    erb :board
  end

end


get '/play/:x/:y' do
  board = db[:board]
  error= board.play(me, params[:x], params[:y])
  if error.nil?
    db[:log] << "#{Time.now.strftime("%H:%M:%S")} player " + me.color + " plays : #{params[:x]}, #{params[:y]}"
  else
    flash[:notice] = error
  end

  if board.winner?

    db[:log] << "#{Time.now.strftime("%H:%M:%S")} : #{session['guid'][0..5]}   wins!"
  end

  redirect '/'
end


get '/reset/:size' do
  db.each_key do |key|
    db[key] = nil
  end
  redirect '/?size='+params[:size]
end


get '/refresh/:action' do


  if params[:action] == "wait-turn" && me == db[:board].current_player
    return "location.reload();"
  end

  if params[:action] == "wait-player" && db[:board].player2 != nil
    return "location.reload();"
  end

  if params[:action] == "watch" && db[:board].turn.to_s != params[:turn]
    return "location.reload();"
  end

  return ""
end
