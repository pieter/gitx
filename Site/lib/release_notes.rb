#!/usr/bin/ruby

RELEASE_NOTES_PATH = File.join(File.dirname(__FILE__), "..", "..", "Documentation", "ReleaseNotes")

module ReleaseNotes

    VERSION_MATCH = /v([0-9.]*).txt$/

    # Find all release not files
    def self.release_files
        notes = Dir.glob(File.join(RELEASE_NOTES_PATH, "v*.txt"))
    
        # Sort files by version number
        notes.sort do |x,y|
            x = x.match VERSION_MATCH
            y = y.match VERSION_MATCH
            # Puts nonmatching files at the bottom
            if !x && y
                1
            elsif !y && x
                -1
            else
                # compare version strings, newest at the top
                y[1].split(".").map { |a| a.to_i } <=> x[1].split(".").map { |a| a.to_i }
            end
        end
    end

    # Aggregate all release notes in a string
    def self.aggregate_notes
        file = ""
        release_files.each do |x|
            file << File.read(x)
            file << "\n"
        end
        file
    end

    def self.last_version
        last_file = release_files.first
        if last_file =~ VERSION_MATCH
            return $1
        end
        nil
    end

    def self.last_notes
        File.read(release_files.first)
    end
end