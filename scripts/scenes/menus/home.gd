extends Control

@onready var username_label = $UserInfo/UsernameLabel
@onready var date_label = $DateTime/Date/DateLabel
@onready var time_label = $DateTime/Time/TimeLabel

func _ready():
	if Config.username:
		username_label.text = Config.username

func _process(_delta):
	var time = Time.get_time_dict_from_system()
	time_label.text = "%02d:%02d" % [time.hour, time.minute]
	
	var date = Time.get_date_dict_from_system()
	date_label.text = "%02d/%02d" % [date.day, date.month]
