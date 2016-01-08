chkWhichNginx := $(shell which nginx)

installedNginxVersion := $(if $(chkWhichNginx),\
$(shell  $(chkWhichNginx) -v 2>&1 | grep -oP '\K[0-9]+\.[0-9]+\.[0-9_]+' ),)

$(info install nginx version - $(installedNginxVersion))
