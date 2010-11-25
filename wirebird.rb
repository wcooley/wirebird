#!/opt/local/bin/ruby

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
smoker_high = 250

# Alerting interval in run cycles (currently 1 minute)
alert_interval = 5

# Data file used for Marshal
alert_f = "alerts.data"

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

print ambient_median,":",smoker_median,":",bird_median,"\n"

wirebird.close

# Alerting Section
#
# If our smoker temperature is totally nuts, we should alert now,
# then wait 5 minutes before alerting again.
# If our sensors read zero, we should alert now.
# If it's at the top or bottom of the clock,
# we should report estimated completion time.

twitter = Twitter::Client.new(:login => 'USERNAME', :password => 'PASSWORD')
now_t = Time.new
alerts = Hash.new 0

if File.exist? alert_f then
	alert_d = File.open alert_f,"r+"
	alerts = Marshal.load alert_d
	alert_d.rewind
else
	alert_d = File.new alert_f,"w+"
end

if smoker_median < smoker_low then
	if ( alerts["cold"] % alert_interval ) == 0 then
		status = Twitter::Status.create(:text => "Smoker cold at "+smoker_median.to_s, :client => twitter)
		print "twitter!\n"
	end
	alerts["cold"] += 1
else
	alerts["cold"] = 0
end
	
if smoker_median > smoker_high then
	if ( alerts["hot"] % alert_interval ) == 0 then
		status = Twitter::Status.create(:text => "Smoker hot at "+smoker_median.to_s, :client => twitter)
		print "twitter!\n"
	end
	alerts["hot"] += 1
else
	alerts["hot"] = 0
end
	
# If the sensors read zero, that means they're probably not connected.
# Time to freak out.
if ambient_median == 32.0 or smoker_median == 32.0 or bird_median == 32.0 then
	if ( alerts["zero"] % alert_interval ) == 0 then
		status = Twitter::Status.create(:text => "Portland, we have a problem--a:"+ambient_median.to_s+" s:"+smoker_median.to_s+" b:"+bird_median.to_s, :client => twitter)
		print "twitter!\n"
	end
	alerts["zero"] += 1
else
	alerts["zero"] = 0
end
	
if now_t.min == 0 or now_t.min == 30 then
	to_finish = log((target_temp-smoker_median)/(bird_median-smoker_median))/heat_transfer_constant
	finish_t = (to_finish.to_i*60)+now_t.to_i
	status = Twitter::Status.create(:text => "Update: estimated finish at "+Time.at(finish_t).to_s, :client => twitter)
	print "twitter!\n"
end

# Dump the data, and let's get out of here!
Marshal.dump alerts, alert_d
alert_d.close
