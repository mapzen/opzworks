# frozen_string_literal: true

# wrap run_locally so we can catch failures
def run_local(cmd)
  require 'English'

  system cmd
  return unless $CHILD_STATUS.exitstatus != 0

  puts 'exit code: ' + $CHILD_STATUS.exitstatus.to_s
  abort('Shell command failed, assuming you want to abort'.foreground(:red))
end
