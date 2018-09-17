require 'pathname'

# Returns pathname of the given fixture or folder in fixtures
#
def fixture_path(*name)
  Pathname.pwd.join('spec', 'fixtures', *name)
end

# Reads and returns fixture contents as a String.
#
def fixture(name)
  File.read(fixture_path(name))
end

# Reads and returns fixture contents parsed from a JSON string.
#
def fixture_json(name)
  JSON.parse(fixture("#{name}.json"))
end
