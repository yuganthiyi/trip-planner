require 'xcodeproj'
project_path = '/Users/dulaboy/Learn/Voyara/Voyara/Voyara.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
group = project.main_group.find_subpath('Voyara', true)

file_ref = group.new_reference('Travel.json')
target.add_resources([file_ref])

project.save
puts "Added Travel.json to Xcode project"
