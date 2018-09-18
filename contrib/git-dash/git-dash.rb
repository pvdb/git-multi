#!/usr/bin/env ruby

TIME_INTERVALS = {

  :minute  => (  MINUTE = 60 ), # seconds
  :hour    => (    HOUR =  60 * MINUTE ),
  :day     => (     DAY =  24 * HOUR   ),
  :week    => (    WEEK =   7 * DAY    ),
  :year    => (    YEAR = 365 * DAY    ),
  :month   => (   MONTH = YEAR / 12    ),
  :quarter => ( QUARTER = YEAR / 4     ),

}.delete_if { |key, _| key == :minute }.sort_by(&:last).to_h.freeze

def time_distance_in_words(seconds)
  case
    when seconds < HOUR    then "less than an hour"
    when seconds < DAY     then "about #{(seconds / HOUR).round} hour(s)"
    when seconds < MONTH   then "about #{(seconds / DAY).round} day(s)"
    when seconds < QUARTER then "about #{(seconds / WEEK).round} week(s)"
    when seconds < YEAR    then "about #{(seconds / MONTH).round} month(s)"
    else                        "about #{(seconds / YEAR).round} year(s)"
  end
end

BLUE = {
  :hour    => "#CCCCFF" ,
  :day     => "#AAAAFF" ,
  :week    => "#8888FF" ,
  :month   => "#6666FF" ,
  :quarter => "#4444FF" ,
  :year    => "#2222FF" ,
}.freeze

GREEN = {
  :hour    => "#CCFFCC" ,
  :day     => "#AAFFAA" ,
  :week    => "#88FF88" ,
  :month   => "#66FF66" ,
  :quarter => "#44FF44" ,
  :year    => "#22FF22" ,
}.freeze

RED = {
  :hour    => "#FFCCCC" ,
  :day     => "#FFAAAA" ,
  :week    => "#FF8888" ,
  :month   => "#FF6666" ,
  :quarter => "#FF4444" ,
  :year    => "#FF2222" ,
}.freeze

if __FILE__ == $0

  $:.unshift File.expand_path('../../lib', __dir__)

  require 'git/multi'

  # get list of GitHub repositories:
  @projects = Git::Multi.repositories

  # annotate the list of projects
  @projects.each do |project|
    def project.age_in_seconds
      (Time.now - pushed_at).to_i
    end
    def project.age_in_words
      time_distance_in_words(age_in_seconds)
    end
  end

  # reverse-order based on the last commit
  @projects.sort_by!(&:pushed_at).reverse!

  require 'erb'

  # generate HTML page with a dashboard of global GitHub repository activity:
  puts ERB.new(File.read(File.join(__dir__, "git-dash.erb"))).result(binding)

end

# That's all Folks!
