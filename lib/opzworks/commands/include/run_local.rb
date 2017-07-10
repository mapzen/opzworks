# frozen_string_literal: true

# wrap run_locally so we can catch failures
def run_local(cmd)
  require 'English'

  system cmd
  return unless $CHILD_STATUS.exitstatus != 0
  if cmd.include?('pull') || cmd.include?('clone')
    puts 'Did you use remote (-b) branch instead of local (-l)?'.foreground(:red)
  end
  puts 'exit code: ' + $CHILD_STATUS.exitstatus.to_s
  exit
end
