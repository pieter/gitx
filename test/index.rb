#!/usr/bin/env arch -i386 macruby

require 'framework.rb'
require 'test/unit'
require 'tmpdir'


# Setup a temporary directory
TMP_DIR = File.join(TEST_TMP_DIR, "index_test")

`rm -rf #{TMP_DIR}`
FileUtils.mkdir_p(TMP_DIR)

def do_git(cmd)
	puts "Running: #{cmd}"
	`cd #{TMP_DIR} && #{cmd}`
end

do_git('git init && touch a && touch b && git add a b && git commit -m"First Commit"')

class IndexTest < Test::Unit::TestCase

	def setup
		@finished = false
		path = NSURL.alloc.initFileURLWithPath(TMP_DIR)
		@repo = PBGitRepository.alloc.initWithURL(path)
		assert(@repo, "Repository creation failed")
		@controller = PBGitIndex.alloc.initWithRepository(@repo, workingDirectory:path)
	end

	def run_loop
		@finished = false
		runloop = NSRunLoop.currentRunLoop
		now = NSDate.date
		date = runloop.limitDateForMode("kCFRunLoopDefaultMode")

		while date = runloop.limitDateForMode("kCFRunLoopDefaultMode") && !@finished
			date = runloop.limitDateForMode("kCFRunLoopDefaultMode")
			 return false if (date.timeIntervalSinceDate(now)) > 2.0
		end
		return true
	end

	def refreshFinished(notification)
		puts "Refresh finished!"
		@finished = true
	end

	def wait_for_refresh
		@controller.refresh
		assert(run_loop, "Refresh finishes in 2 seconds")
	end

	def test_a
		NSNotificationCenter.defaultCenter.addObserver(self,
			selector:"refreshFinished:",
			name:"PBGitIndexFinishedIndexRefresh",
			object:@controller);

		wait_for_refresh
		assert(@controller.indexChanges.empty?, "No changes")
		do_git('rm a')
		wait_for_refresh
		assert(@controller.indexChanges.count == 1, "One change")
		do_git('touch a')
		wait_for_refresh
		assert(@controller.indexChanges.empty?, "No changes anymore")

		do_git('echo "waa" > a')
		wait_for_refresh
		assert(@controller.indexChanges.count == 1, "Another change")
		previous_state = @controller.indexChanges[0].status

		do_git('rm a')
		wait_for_refresh
		assert(@controller.indexChanges.count == 1, "Still one change")
		# 2 == DELETED, see PBChangedFile.h
		assert_equal(@controller.indexChanges[0].status, 2, "File status has changed")
		do_git('git checkout a')

		do_git('touch c')
		wait_for_refresh
		assert(@controller.indexChanges.count == 1)
		file = @controller.indexChanges[0]
		assert_equal(file.status, 0, "File is new")
		
		do_git('git add c')
		wait_for_refresh
		assert(@controller.indexChanges.count == 1)
		assert_equal(file, @controller.indexChanges[0], "Still the same file")
		assert_equal(file.status, 0, "Still new")
	end

end