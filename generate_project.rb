require "fileutils"
require "xcodeproj"

PROJECT_NAME = "ExpiryMate"
IOS_VERSION = "17.0"
APP_DIR = "ExpiryMate"
WIDGET_DIR = "ExpiryMateWidget"
SHARED_DIR = "Shared"

project_path = "#{PROJECT_NAME}.xcodeproj"
FileUtils.rm_rf(project_path)
project = Xcodeproj::Project.new(project_path)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2600"
project.root_object.attributes["LastUpgradeCheck"] = "2600"

app_target = project.new_target(:application, PROJECT_NAME, :ios, IOS_VERSION)
widget_target = project.new_target(:app_extension, "#{PROJECT_NAME}Widget", :ios, IOS_VERSION)

project.build_configurations.each do |config|
  config.build_settings["SWIFT_VERSION"] = "5.0"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = IOS_VERSION
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["DEVELOPMENT_TEAM"] = ""
  config.build_settings["CLANG_ENABLE_MODULES"] = "YES"
end

def apply_settings(target, settings)
  target.build_configurations.each do |config|
    settings.each do |key, value|
      config.build_settings[key] = value
    end
  end
end

common_settings = {
  "SWIFT_VERSION" => "5.0",
  "IPHONEOS_DEPLOYMENT_TARGET" => IOS_VERSION,
  "TARGETED_DEVICE_FAMILY" => "1",
  "CODE_SIGN_STYLE" => "Automatic",
  "DEVELOPMENT_TEAM" => "",
  "CURRENT_PROJECT_VERSION" => "1",
  "MARKETING_VERSION" => "1.0",
  "GENERATE_INFOPLIST_FILE" => "NO",
  "CLANG_ENABLE_MODULES" => "YES",
  "ENABLE_USER_SCRIPT_SANDBOXING" => "NO"
}

apply_settings(app_target, common_settings.merge(
  "PRODUCT_BUNDLE_IDENTIFIER" => "com.example.expirymate",
  "PRODUCT_NAME" => PROJECT_NAME,
  "INFOPLIST_FILE" => "#{APP_DIR}/Info.plist",
  "CODE_SIGN_ENTITLEMENTS" => "#{APP_DIR}/ExpiryMate.entitlements",
  "SWIFT_EMIT_LOC_STRINGS" => "YES"
))

apply_settings(widget_target, common_settings.merge(
  "PRODUCT_BUNDLE_IDENTIFIER" => "com.example.expirymate.widget",
  "PRODUCT_NAME" => "$(TARGET_NAME)",
  "INFOPLIST_FILE" => "#{WIDGET_DIR}/Info.plist",
  "CODE_SIGN_ENTITLEMENTS" => "#{WIDGET_DIR}/ExpiryMateWidget.entitlements",
  "APPLICATION_EXTENSION_API_ONLY" => "YES",
  "SKIP_INSTALL" => "YES",
  "SWIFT_EMIT_LOC_STRINGS" => "YES"
))

main_group = project.main_group
app_group = main_group.new_group(APP_DIR)
widget_group = main_group.new_group(WIDGET_DIR)
shared_group = main_group.new_group(SHARED_DIR)

def add_files(target, group, pattern)
  Dir.glob(pattern).sort.each do |path|
    ref = group.new_file(path)
    target.add_file_references([ref])
  end
end

def add_resources(target, group, pattern)
  Dir.glob(pattern).sort.each do |path|
    ref = group.files.find { |file| file.path == path } || group.new_file(path)
    target.resources_build_phase.add_file_reference(ref, true)
  end
end

add_files(app_target, app_group, "#{APP_DIR}/**/*.swift")
add_files(widget_target, widget_group, "#{WIDGET_DIR}/**/*.swift")
add_files(app_target, shared_group, "#{SHARED_DIR}/**/*.swift")
Dir.glob("#{SHARED_DIR}/**/*.swift").sort.each do |path|
  ref = shared_group.files.find { |file| file.path == path } || shared_group.new_file(path)
  widget_target.add_file_references([ref])
end

add_resources(app_target, app_group, "#{APP_DIR}/**/*.xcassets")

app_target.add_dependency(widget_target)
embed_phase = app_target.new_copy_files_build_phase("Embed App Extensions")
embed_phase.dst_subfolder_spec = "13"
embed_phase.add_file_reference(widget_target.product_reference)

project.save
puts "Generated #{project_path}"
