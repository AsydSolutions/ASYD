# Returns true if the string is not a number
#
class String
  def nan?
    self !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
  end
end

# Return code: 6
class SilentFormatException < StandardError
end

# Return code: 5
class FormatException < StandardError
end

# Return code: 4
class ExecutionError < StandardError
end
