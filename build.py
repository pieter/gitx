#!/usr/bin/env python

import argh
import subprocess
import os

import package
import sign

app="GitX"
product="%s.app" % (app,)
label="dev"
base_version="0.15"

artifact_prefix= "%s-%s" % (app, label)
workspace="%s.xcodeproj/project.xcworkspace" % (app,)
debug_configuration="Debug"
release_configuration="Release"
agvtool="xcrun agvtool"
release_branch="master"

configuration=""
clean=""
pause=3

build_base_dir = os.path.join(os.getcwd(), "build")
                         
class BuildError(RuntimeError):
    pass

def clean():
    clean_config(debug_configuration)
    clean_config(release_configuration)

def release():
    try:
        assert_clean()
        assert_branch(release_branch)
        build_number = commit_count()
        set_versions(base_version, build_number, "dev")
        
        build_config(release_configuration)

        built_product = os.path.join(build_dir, product)
        sign_app(built_product)

        image_path = os.path.join(build_dir, "%s-%s.dmg" % (artifact_prefix, build_number))
        image_name = "%s %s" % (app, build_number)
        package_app(built_product, image_path, image_name)
        
    except BuildError as e:
        print("error: %s" % (str(e),))

def debug():
    try:
        build_dir = os.path.join
        build_config(debug_configuration)
        
    except BuildError as e:
        print("error: %s" % (str(e),))


@argh.arg("configuration", choices=['debug','release'])
def build(configuration):
    if configuration == "debug":
        debug()
    if configuration == "release":
        release()

def assert_clean():
    status = subprocess.check_output(["git", "status", "--porcelain"])
    if len(status):
        raise BuildError("Working copy must be clean")

def assert_branch(branch="master"):
    ref = subprocess.check_output(["git", "rev-parse", "HEAD"])
    if ref != branch:
        raise BuildError("HEAD must be %s" % (branch,))

def build_config(config):
    build_dir = os.path.join(build_base_dir, config)
    xcodebuild(app, workspace, config, ["build"], build_dir)

def clean_config(config):
    build_dir = os.path.join(build_base_dir, config)
    xcodebuild(app, workspace, config, ["clean"], build_dir)

def commit_count():
    count = subprocess.check_output(["git", "rev-list", "HEAD", "--count"])
    return count

def set_versions(base_version, build_number, label):
    print(subprocess.check_output(["agvtool", "mvers", "-terse1"]))
    print(subprocess.check_output(["agvtool", "vers", "-terse"]))
    marketing_version = "%s.%s %s" % (base_version, build_number, label)
    build_version = "%s.%s" % (base_version, build_number)
    subprocess.check_call(["agvtool", "new-marketing-version", marketing_version])
    subprocess.check_call(["agvtool", "new-version", "-all", build_version])

def xcodebuild(scheme, workspace, configuration, commands, build_dir):
    cmd = ["xcrun", "xcodebuild", "-scheme", scheme, "-workspace", workspace, "-configuration", configuration]
    cmd = cmd + commands
    cmd.append('CONFIGURATION_BUILD_DIR=%s' % (build_dir))
    try:
        output = subprocess.check_output(cmd)
        return output
    except subprocess.CalledProcessError as e:
        raise BuildError(str(e))

def sign_app(app_path):
    sign.sign_everything_in_app(app_path, verbose=2)

def package_app(app_path, image_path, image_name):
    package.package(app_path, image_path, image_name)

if __name__ == "__main__":
        argh.dispatch_commands([clean, build])

