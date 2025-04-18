# acl disk permissions

function sv3_readwrite_recurse() {
  otheruser=$1
  dirtoshare=$2
  if [[ "${dirtoshare}" == "" ]]; then echo "syntax: cmd [otheruser] [dirtoshare]"; return; fi
  if [[ ! -d "${dirtoshare}" ]]; then echo "folder not found: ${dirtoshare}"; return; fi
  setfacl -m u:$(id -u ${otheruser}):rwx ${dirtoshare}
  find ${dirtoshare} -type f -exec setfacl -m u:$(id -u ${otheruser}):rw {} \;
  find ${dirtoshare} -type d -exec setfacl -m d:u:$(id -u ${otheruser}):rwx {} \;
  find ${dirtoshare} -type d -exec setfacl -m d:u:$(id -u):rwx {} \;
  setfacl -m d:u:$(id -u ${otheruser}):rwx ${dirtoshare}
  setfacl -m d:u:$(id -u):rwx ${dirtoshare}
  getfacl ${dirtoshare}
}
export -f sv3_readwrite_recurse

function sv3_readwrite_norecurse() {
  otheruser=$1
  dirtoshare=$2
  if [[ "${dirtoshare}" == "" ]]; then echo "syntax: cmd [otheruser] [dirtoshare]"; return; fi
  if [[ ! -d "${dirtoshare}" ]]; then echo "folder not found: ${dirtoshare}"; return; fi
  setfacl -m u:$(id -u ${otheruser}):rwx ${dirtoshare}
  setfacl -m d:u:$(id -u ${otheruser}):rwx ${dirtoshare}
  setfacl -m d:u:$(id -u):rwx ${dirtoshare}
  getfacl ${dirtoshare}
}
export -f sv3_readwrite_norecurse

function sv3_readonly_recurse() {
  otheruser=$1
  dirtoshare=$2
  if [[ "${dirtoshare}" == "" ]]; then echo "syntax: cmd [otheruser] [dirtoshare]"; return; fi
  if [[ ! -d "${dirtoshare}" ]]; then echo "folder not found: ${dirtoshare}"; return; fi
  setfacl -m u:$(id -u ${otheruser}):rx ${dirtoshare}
  find ${dirtoshare} -type f -exec setfacl -m u:$(id -u ${otheruser}):r {} \;
  find ${dirtoshare} -type d -exec setfacl -m u:$(id -u ${otheruser}):rx {} \;
  find ${dirtoshare} -type d -exec setfacl -m d:u:$(id -u ${otheruser}):rx {} \;
  getfacl ${dirtoshare}
}
export -f sv3_readonly_recurse

function sv3_readonly_norecurse() {
  otheruser=$1
  dirtoshare=$2
  if [[ "${dirtoshare}" == "" ]]; then echo "syntax: cmd [otheruser] [dirtoshare]"; return; fi
  if [[ ! -d "${dirtoshare}" ]]; then echo "folder not found: ${dirtoshare}"; return; fi
  setfacl -m u:$(id -u ${otheruser}):rx ${dirtoshare}
  getfacl ${dirtoshare}
}
export -f sv3_readonly_norecurse

sv3_777() {
    targetdir="$1"
    if [[ -z "$targetdir" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
    if [[ ! -d "$targetdir" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
    setfacl -bR "${targetdir}"
    setfacl -kR "${targetdir}"
    setfacl -R -m u::rwx,g::rwx,o::rwx ${targetdir}
    setfacl -R -m d:u::rwx,d:g::rwx,d:o::rwx ${targetdir}
    getfacl "${targetdir}"
}
export -f sv3_777

sv3_removeperms() {
    targetdir="$1"
    if [[ -z "$targetdir" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
    if [[ ! -d "$targetdir" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
    echo remove all permissions for ${targetdir}
    setfacl -bR "${targetdir}"
    setfacl -kR "${targetdir}"
}
export -f sv3_removeperms

sv3_public_readonly() {
    targetdir="$1"
    if [[ -z "$targetdir" ]]; then echo "Usage: cmd <directory>"; return 1 ; fi
    if [[ ! -d "$targetdir" ]]; then echo "Error: Directory '$targetdir' does not exist." ; return 1 ; fi
    find "$targetdir" -type d -exec setfacl -m u::rwx,g::rx,o::rx {} \;
    find "$targetdir" -type f -exec setfacl -m u::rw,g::r,o::r {} \;
    find "$targetdir" -type d -exec setfacl -m d:u::rwx,d:g::rx,d:o::rx {} \;
}
export -f sv3_public_readonly
