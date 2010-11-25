#!/usr/bin/env ruby1.8

include Math
include Marshal

require "time"
require "serialport.so"

require "rubygems"
gem "twitter4r", "0.3.0"
require "twitter"


# Initialize some variables
heat_transfer_constant = -0.0022
target_temp = 160.0

# Targets
smoker_low = 200
smoker_high = 225

# Alerting interval in run cycles (currently 1 minute)
alert_interval = 5

# Data file used for Marshal
alert_f = "/Users/cchen/wirebird/alerts.data"

ambient = Array.new
smoker = Array.new
bird = Array.new

wirebird = SerialPort.new('/dev/tty.usbserial-A4001mzW', 9600, 8, 1, SerialPort::NONE)
wirebird.dtr = 1

while bird.nitems < 8 do
	reading = wirebird.gets
	if reading =~ /^Celsius:/
		parsed = reading.split(" ")
		temp_b = ((((parsed[1].to_f)/100)*9)/5)+32
		bird.push(temp_b)
		temp_b = ((((parsed[2].to_f)/100)*9)/5)+32
		smoker.push(temp_b)
		temp_b = ((((parsed[3].to_f)/100)*9)/5)+32
		ambient.push(temp_b)
	end
end

ambient.sort! 
smoker.sort! 
bird.sort! 

ambient_median = (ambient[3]+ambient[4])/2
smoker_median = (smoker[3]+smoker[4])/2
bird_median = (bird[3]+bird[4])/2

print ambient_median," ambient ",smoker_median," smoker ",bird_median," bird\n"


wirebird.close
