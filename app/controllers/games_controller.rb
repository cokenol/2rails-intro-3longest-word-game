require 'pry-byebug'
require 'open-uri'
require 'json'
require 'date'

class GamesController < ApplicationController
  def new
    @letters = []
    @start_time = Time.now
    @letters << ('A'..'Z').to_a.sample until @letters.size == 10
    @letters[rand(0...10)] = %w[A E I O U][rand(0..4)] until @letters.filter_map { |a| %w[a e i o u].include?(a.downcase) }.count > 1
    session[:grid] = @letters
  end

  def score
    @ori = session[:grid].join
    @input = params['longest-word']
    @error = grid_wordcheck(@input, @ori)
    @check = check_word(@input, params['start-time'], Time.now) if @error[:found]
    session[:total].nil? ? session[:total] = @check[:score] : session[:total] += @check[:score]
    session[:count].nil? ? session[:count] = 1 : session[:count] += 1
    @total_score = session[:total]
    @total_tries = session[:count]
  end

  # def calc
  #   session[:total].nil? session[:total] =
  # end

  def check_word(attempt, start_time, end_time)
    # Find longest word
    start_t = DateTime.parse(start_time)
    attempt_duration = end_time - start_t
    url = "https://wagon-dictionary.herokuapp.com/#{attempt}"
    check_word = JSON.parse(URI.open(url).read).values
    hash = {}
    hash[:time] = attempt_duration
    hash[:score] = check_word[0] ? attempt.length**2 / attempt_duration : 0
    hash[:message] =  check_word[0] ? 'Well Done!' : 'Not an english word'
    hash[:score] = hash[:score].round(2)
    hash
  end

  def grid_wordcheck(attempt, grid)
    attempt_h = attempt.downcase.chars.map.tally
    grid_h = grid.downcase.chars.map.tally
    attempt_h.keys.map do |b|
      if grid_h.keys.include?(b)
        # puts "#{attempt_h[b]} #{grid_h[b]}"
        return { found: false, score: 0, message: "#{attempt.upcase} grid letters overused from #{grid}" } if attempt_h[b] > grid_h[b]
      else
        return { found: false, score: 0, message: "#{attempt} not in the grid of #{grid}" }
      end
    end
    { found: true }
  end
end
