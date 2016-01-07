
cmdExistClient = java -jar $(EXIST_HOME)/start.jar client -sqx -u $(1) -P $(2)
smFindUsersByUsername = sm$(:)find-users-by-username('$(1)')
smFindGroupsByGroupname = sm$(:)find-groups-by-groupname('$(1)')
smRemoveGroup = sm$(:)remove-group('$(1)')
smIsDBA = sm$(:)is-dba('$(1)')
smIsAccountEnabled = sm$(:)is-account-enabled('$(1)')
smIsAuthenticated = sm$(:)is-authenticated()
smCreateAccount = sm$(:)create-account('$(1)','$(2)','$(3)')

isUser = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "$(call smFindUsersByUsername,$(1))" | \
 $(call cmdExistClient,admin,$(P)) | \
 tail -1 | \
 grep '$(1)')")

isGroup = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "$(call smFindGroupsByGroupname,$(1))" | \
 $(call cmdExistClient,admin,$(P)) | \
 tail -1 | \
 grep '$(1)')")

createDBA = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "sm$(:)create-account('$(1)','$(2)','$(3)')" | \
 $(call cmdExistClient,admin,$(P)) | \
 tail -1 )")

removeGroup = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "sm:remove-group('$(1)')" | \
 $(call cmdExistClient,admin,$(P)))")

isAuthenticated  = $(shell echo "$$(cd $(EXIST_HOME);\
 echo 'sm:is-authenticated()' |\
 $(call cmdExistClient,$(1),$(2)) | \
 tail -1 )")


$(EXIST_PASS):
	@echo "## $(notdir $@) ##"
	@$(call assert-file-present,$(ACCESS_TOKEN_PATH))
	@echo "GIT_USER: $(GIT_USER) "
ifeq ($(call isUser,admin),admin)
	@echo 'admin is in eXists list of users'
endif
ifeq ($(call isUser,$(GIT_USER)),)
	@echo '$(GIT_USER) does not exist in eXists list of users'
endif
ifeq ($(call isGroup,$(GIT_USER)),)
	@echo '$(GIT_USER) does not exist in eXists list of groups'
endif
	@echo "Create a new default password using git user name and github access token"
ifeq ($(call isUser,$(GIT_USER)),)
	@echo 'no user but check for users group account an remove if exists'
	@$(if $(call isGroup,$(GIT_USER)),\
 $(call removeGroup,$(GIT_USER)),echo 'OK')
	@$(call createDBA,$(GIT_USER),$(ACCESS_TOKEN))
endif
ifeq ($(call isUser,$(GIT_USER)),$(GIT_USER))
	@echo '$(GIT_USER) is in eXists list of users'
endif
ifeq ($(call isGroup,$(GIT_USER)),$(GIT_USER))
	@echo '$(GIT_USER) is in eXists list of groups'
endif
	@echo "login using git user name and github access token"
	@echo "$(call isAuthenticated,$(GIT_USER),$(ACCESS_TOKEN))"
	@echo '-------------------------------------------------------------------'

