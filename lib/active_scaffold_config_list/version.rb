module ActiveScaffoldConfigList
  module Version
    MAJOR = 4
    MINOR = 1
    PATCH = '0.pre' # release 4.1.0 when AS 4.4.0 is supported, update dependency in gemspec

    STRING = [MAJOR, MINOR, PATCH].compact.join('.')
  end
end
