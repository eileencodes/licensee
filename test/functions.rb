# Pulled from helper.rb because something in the test suite monkey patches benchmarking

require 'securerandom'

def fixtures_base
  File.expand_path "fixtures", File.dirname( __FILE__ )
end

def fixture_path(fixture)
  File.expand_path fixture, fixtures_base
end

def license_from_path(path)
  license = File.open(path).read.split("---").last
  license.sub! "[fullname]", "Ben Balter"
  license.sub! "[year]", "2014"
  license.sub! "[email]", "ben@github.invalid"
  license
end

class FakeBlob
  attr_reader :content

  def initialize(content)
    @content = content
  end

  def size
    content.size
  end

  def similarity(other)
    Rugged::Blob::HashSignature.compare(self.hashsig, other)
  end

  def hashsig(options = 0)
    @hashsig ||= Rugged::Blob::HashSignature.new(content, options)
  end
end

def chaos_monkey(string)
  lines = string.each_line.to_a

  Random.rand(5).times do
    lines[Random.rand(lines.size)] = SecureRandom.base64(Random.rand(80)) + "\n"
  end

  lines.join('')
end

def verify_license_file(license, chaos = false, wrap=false)
  expected = File.basename(license, ".txt")

  text = license_from_path(license)
  text = chaos_monkey(text) if chaos
  text = wrap(text, wrap) if wrap

  blob = FakeBlob.new(text)
  license_file = Licensee::LicenseFile.new(blob)

  actual = license_file.match
  assert actual, "No match for #{expected}."
  assert_equal expected, actual.name, "expeceted #{expected} but got #{actual.name} for .match. Matches: #{license_file.matches}"
end

def wrap(text, line_width=80)
  text = text.clone
  text.gsub! /([^\n])\n([^\n])/, '\1 \2'
  text = text.split("\n").collect do |line|
    line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
  end * "\n"
  text.strip
end
