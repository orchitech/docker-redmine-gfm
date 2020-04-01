#!/usr/bin/awk -f

function dockercmd(cmd)
{
  if (!match(cmd, /^RUN[ \t]+/)) {
    return;
  }
  cmd = substr(cmd, RLENGTH + 1);
  if (!match(cmd, /bundle install.*for adapter.*echo.*bundle install/)) {
    return;
  }
  matched++;
  printf "%s", cmd;
}

# a poor man's Dockerfile parser
BEGIN {
  cont = 0;
  cmd = "";
  matched = 0;
}
!cont && (NF == 0 || $1 ~ /^#/) {
  next;
}
$1 ~ /^[^#]/ {
  cont = 0;
}
/^[ \t]*[^#].*\\[ \t]*$/ {
  cont = 1;
}
{
  cmd = cmd $0 RS;
}
!cont && length(cmd) > 0 {
  dockercmd(cmd);
  cmd = "";
}
END {
  if (length(cmd) > 0) {
    dockercmd(cmd);
  }
  if (matched != 1) {
    print "Cannot extract install script!" > "/dev/stderr"
    exit 1;
  }
}
