require 'tempfile'

task :postmortem do
  
  POSTMORTEM_TEMPLATE = <<POSTMORTEM
### Description of Incident

### Description of Root Cause

### How it was Stabilized or Fixed

### Timeline of Actions Taken To Resolve

- 3:00 PM Something
- 3:03 PM Something else

### How It Affected Customers

Severity 1, 2, 3.

### How to We Protect from Happening Again
POSTMORTEM

  t = Tempfile.new("postmortem.txt")
  t.write(POSTMORTEM_TEMPLATE)
  t.close
  system %Q{cat #{t.path} | /usr/bin/mate}
end