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


function sv3_775() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::rwx,o::r-x ${targetdir}
  setfacl -R -m d:u::rwx,d:g::rwx,d:o::r-x ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}


# respecting executables
function sve3_775() {
  local targetdir="$1"
  if [[ -z "$targetdir" ]]; then
    echo "Usage: cmd <directory>"
    return 1
  fi
  if [[ ! -d "$targetdir" ]]; then
    echo "Error: Directory '$targetdir' does not exist."
    return 1
  fi

  # Existing:
  # - dirs -> 775 (u=rwx,g=rwx,o=rx)
  # - files -> 664 (u=rw,g=rw,o=r)
  # - files that already had any execute bit -> 775 (u=rwx,g=rwx,o=rx)
  find "$targetdir" -type d -exec setfacl -m u::rwx,g::rwx,o::r-x {} +

  find "$targetdir" -type f ! -perm /111 -exec setfacl -m u::rw-,g::rw-,o::r-- {} +
  find "$targetdir" -type f   -perm /111 -exec setfacl -m u::rwx,g::rwx,o::r-x {} +

  # Defaults (new items created under targetdir):
  # - dirs default -> 775
  # - files default -> 664
  # Note: default ACLs don't force a file to be executable; the creator/umask decides that.
  setfacl -m d:u::rwx,d:g::rwx,d:o::r-x "$targetdir"
  setfacl -m d:u::rw-,d:g::rw-,d:o::r-- "$targetdir"

  # Ensure the current user retains full access (effective + default)
  setfacl -m u:$(id -u):rwx,d:u:$(id -u):rwx "$targetdir"

  getfacl "$targetdir"
}



function sv3_770() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::rwx,o::--- ${targetdir}
  setfacl -R -m d:u::rwx,d:g::rwx,d:o::--- ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}


function sv3_755() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::r-x,o::r-x ${targetdir}
  setfacl -R -m d:u::rwx,d:g::r-x,d:o::r-x ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}


function sv3_750() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::r-x,o::--- ${targetdir}
  setfacl -R -m d:u::rwx,d:g::r-x,d:o::--- ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}


function sv3_700() {
  targetdir="$1"
  if [[ -z "${targetdir}" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
  if [[ ! -d "${targetdir}" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
  setfacl -R -m u::rwx,g::---,o::--- ${targetdir}
  setfacl -R -m d:u::rwx,d:g::---,d:o::--- ${targetdir}
  setfacl -R -m d:u:$(id -u):rwx "${targetdir}"
  getfacl "${targetdir}"
}


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

