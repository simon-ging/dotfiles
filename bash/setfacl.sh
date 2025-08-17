# acl disk permissions

function sv3_removeperms() {
  # remove all permissions for a directory
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  echo remove all permissions for ${targetdir}
  setfacl -bR "${targetdir}"
  setfacl -kR "${targetdir}"
}
export -f sv3_removeperms

# the following set the permissions similar to chmod
# as well as setting the default flags to be the same for files created in the future
# finally they give the owner (the one who executes the function) full permissions
# such that if the new user creates a new file, the folder owner will have full permissions.

function sv3_777() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::rwx,o::rwx ${targetdir}
  setfacl -R -m d:u::rwx,d:g::rwx,d:o::rwx ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_777

function sv3_775() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::rwx,o::r-x ${targetdir}
  setfacl -R -m d:u::rwx,d:g::rwx,d:o::r-x ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_775

function sv3_770() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::rwx,o::--- ${targetdir}
  setfacl -R -m d:u::rwx,d:g::rwx,d:o::--- ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_770

function sv3_755() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::r-x,o::r-x ${targetdir}
  setfacl -R -m d:u::rwx,d:g::r-x,d:o::r-x ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_755

function sv3_750() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::r-x,o::--- ${targetdir}
  setfacl -R -m d:u::rwx,d:g::r-x,d:o::--- ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_750

function sv3_700() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::---,o::--- ${targetdir}
  setfacl -R -m d:u::rwx,d:g::---,d:o::--- ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_700

# these functions share folders with a specific user.

function sv3_readwrite_recurse() {
  otheruser=$1
  targetdir=$2
  if [[ ""${targetdir}"" == "" ]]; then echo "syntax: cmd [otheruser] [targetdir]"; return; fi
  if [[ ! -d ""${targetdir}"" ]]; then echo "folder not found: "${targetdir}""; return; fi
  setfacl -R -m u:$(id -u ${otheruser}):rwx "${targetdir}"
  setfacl -R -m d:u:$(id -u ${otheruser}):rwx "${targetdir}"
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_readwrite_recurse

function sv3_readwrite_norecurse() {
  otheruser=$1
  targetdir=$2
  if [[ ""${targetdir}"" == "" ]]; then echo "syntax: cmd [otheruser] [targetdir]"; return; fi
  if [[ ! -d ""${targetdir}"" ]]; then echo "folder not found: "${targetdir}""; return; fi
  setfacl -m u:$(id -u ${otheruser}):rwx "${targetdir}"
  setfacl -m d:u:$(id -u ${otheruser}):rwx "${targetdir}"
  setfacl -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_readwrite_norecurse

function sv3_readonly_recurse() {
  otheruser=$1
  targetdir=$2
  if [[ ""${targetdir}"" == "" ]]; then echo "syntax: cmd [otheruser] [targetdir]"; return; fi
  if [[ ! -d ""${targetdir}"" ]]; then echo "folder not found: "${targetdir}""; return; fi
  setfacl -R -m u:$(id -u ${otheruser}):r-x "${targetdir}"
  setfacl -R -m d:u:$(id -u ${otheruser}):r-x "${targetdir}"
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_readonly_recurse

function sv3_readonly_norecurse() {
  otheruser=$1
  targetdir=$2
  if [[ ""${targetdir}"" == "" ]]; then echo "syntax: cmd [otheruser] [targetdir]"; return; fi
  if [[ ! -d ""${targetdir}"" ]]; then echo "folder not found: "${targetdir}""; return; fi
  setfacl -m u:$(id -u ${otheruser}):r-x "${targetdir}"
  setfacl -m d:u:$(id -u ${otheruser}):r-x "${targetdir}"
  setfacl -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}
export -f sv3_readonly_norecurse
