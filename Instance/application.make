#
#   application.make
#
#   Instance Makefile rules to build GNUstep-based applications.
#
#   Copyright (C) 1997, 2001, 2002 Free Software Foundation, Inc.
#
#   Author:  Nicola Pero <nicola@brainstorm.co.uk>
#   Author:  Ovidiu Predescu <ovidiu@net-community.com>
#   Based on the original version by Scott Christley.
#
#   This file is part of the GNUstep Makefile Package.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   
#   You should have received a copy of the GNU General Public
#   License along with this library; see the file COPYING.LIB.
#   If not, write to the Free Software Foundation,
#   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#
# Include in the common makefile rules
#
ifeq ($(RULES_MAKE_LOADED),)
include $(GNUSTEP_MAKEFILES)/rules.make
endif

#
# The name of the application is in the APP_NAME variable.
# The list of application resource directories is in xxx_RESOURCE_DIRS
# The list of application resource files is in xxx_RESOURCE_FILES
# The list of localized resource files is in xxx_LOCALIZED_RESOURCE_FILES
# The list of supported languages is in xxx_LANGUAGES
# The name of the application icon (if any) is in xxx_APPLICATION_ICON
# The name of the app class is xxx_PRINCIPAL_CLASS (defaults to NSApplication).
# The name of a file containing info.plist entries to be inserted into
# Info-gnustep.plist (if any) is xxxInfo.plist
# where xxx is the application name
#

.PHONY: internal-app-all \
        internal-app-install \
        internal-app-uninstall \
        internal-application-build-template \
        _FORCE

ALL_GUI_LIBS =								     \
    $(shell $(WHICH_LIB_SCRIPT)						     \
     $(ALL_LIB_DIRS)							     \
     $(ADDITIONAL_GUI_LIBS) $(AUXILIARY_GUI_LIBS) $(GUI_LIBS)		     \
     $(BACKEND_LIBS) $(ADDITIONAL_TOOL_LIBS) $(AUXILIARY_TOOL_LIBS)	     \
     $(FND_LIBS) $(ADDITIONAL_OBJC_LIBS) $(AUXILIARY_OBJC_LIBS) $(OBJC_LIBS) \
     $(SYSTEM_LIBS) $(TARGET_SYSTEM_LIBS)				     \
        debug=$(debug) profile=$(profile) shared=$(shared)		     \
	libext=$(LIBEXT) shared_libext=$(SHARED_LIBEXT))

APP_DIR_NAME = $(GNUSTEP_INSTANCE:=.$(APP_EXTENSION))

GNUSTEP_SHARED_INSTANCE_BUNDLE_RESOURCE_PATH = $(APP_DIR_NAME)/Resources
include $(GNUSTEP_MAKEFILES)/Instance/Shared/bundle.make

# Support building NeXT applications
ifneq ($(OBJC_COMPILER), NeXT)
APP_FILE = \
    $(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR)/$(GNUSTEP_INSTANCE)$(EXEEXT)
else
APP_FILE = $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE)$(EXEEXT)
endif

#
# Internal targets
#

$(APP_FILE): $(OBJ_FILES_TO_LINK)
	$(LD) $(ALL_LDFLAGS) -o $(LDOUT)$@ $(OBJ_FILES_TO_LINK) \
	      $(ALL_GUI_LIBS)
ifeq ($(OBJC_COMPILER), NeXT)
	@$(TRANSFORM_PATHS_SCRIPT) $(subst -L,,$(ALL_LIB_DIRS)) \
		>$(APP_DIR_NAME)/library_paths.openapp
# This is a hack for OPENSTEP systems to remove the iconheader file
# automatically generated by the makefile package.
	rm -f $(GNUSTEP_INSTANCE).iconheader
else
	@$(TRANSFORM_PATHS_SCRIPT) $(subst -L,,$(ALL_LIB_DIRS)) \
	>$(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR)/library_paths.openapp
endif

#
# Compilation targets
#
ifeq ($(OBJC_COMPILER), NeXT)
internal-app-all:: before-$(GNUSTEP_INSTANCE)-all \
                   $(GNUSTEP_INSTANCE).iconheader \
                   $(GNUSTEP_OBJ_DIR) \
                   $(APP_DIR_NAME) \
                   $(APP_FILE) \
                   shared-instance-bundle-all \
                   after-$(GNUSTEP_INSTANCE)-all

$(GNUSTEP_INSTANCE).iconheader:
	@(echo "F	$(GNUSTEP_INSTANCE).$(APP_EXTENSION)	$(GNUSTEP_INSTANCE)	$(APP_EXTENSION)"; \
	  echo "F	$(GNUSTEP_INSTANCE)	$(GNUSTEP_INSTANCE)	app") >$@

else

internal-app-all:: before-$(GNUSTEP_INSTANCE)-all \
                   $(GNUSTEP_OBJ_DIR) \
                   $(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR) \
                   $(APP_FILE) \
                   internal-application-build-template \
                   $(APP_DIR_NAME)/Resources \
                   $(APP_DIR_NAME)/Resources/Info-gnustep.plist \
		   $(APP_DIR_NAME)/Resources/$(GNUSTEP_INSTANCE).desktop \
                   shared-instance-bundle-all \
                   after-$(GNUSTEP_INSTANCE)-all

$(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR):
	@$(MKDIRS) $@

ifeq ($(GNUSTEP_FLATTENED),)
internal-application-build-template: $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE)

$(APP_DIR_NAME)/$(GNUSTEP_INSTANCE):
	cp $(GNUSTEP_MAKEFILES)/executable.template \
	   $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE); \
	chmod a+x $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE)
else
internal-application-build-template:

endif
endif

PRINCIPAL_CLASS = $(strip $($(GNUSTEP_INSTANCE)_PRINCIPAL_CLASS))

ifeq ($(PRINCIPAL_CLASS),)
  PRINCIPAL_CLASS = NSApplication
endif

APPLICATION_ICON = $($(GNUSTEP_INSTANCE)_APPLICATION_ICON)

MAIN_MODEL_FILE = $(strip $(subst .gmodel,,$(subst .gorm,,$(subst .nib,,$($(GNUSTEP_INSTANCE)_MAIN_MODEL_FILE)))))

$(APP_DIR_NAME)/Resources/Info-gnustep.plist: _FORCE
	@(echo "{"; echo '  NOTE = "Automatically generated, do not edit!";'; \
	  echo "  NSExecutable = \"$(GNUSTEP_INSTANCE)\";"; \
	  echo "  NSMainNibFile = \"$(MAIN_MODEL_FILE)\";"; \
	  if [ "$(APPLICATION_ICON)" != "" ]; then \
	    echo "  NSIcon = \"$(APPLICATION_ICON)\";"; \
	  fi; \
	  echo "  NSPrincipalClass = \"$(PRINCIPAL_CLASS)\";"; \
	  echo "}") >$@
	  @ if [ -r "$(GNUSTEP_INSTANCE)Info.plist" ]; then \
	    plmerge $@ $(GNUSTEP_INSTANCE)Info.plist; \
	  fi

$(APP_DIR_NAME)/Resources/$(GNUSTEP_INSTANCE).desktop: \
		$(APP_DIR_NAME)/Resources/Info-gnustep.plist
	@pl2link $^ $(APP_DIR_NAME)/Resources/$(GNUSTEP_INSTANCE).desktop

_FORCE::

internal-app-install:: $(GNUSTEP_APPS)
	rm -rf $(GNUSTEP_APPS)/$(APP_DIR_NAME); \
	$(TAR) cf - $(APP_DIR_NAME) | (cd $(GNUSTEP_APPS); $(TAR) xf -)
ifneq ($(CHOWN_TO),)
	$(CHOWN) -R $(CHOWN_TO) $(GNUSTEP_APPS)/$(APP_DIR_NAME)
endif
ifeq ($(strip),yes)
	$(STRIP) $(GNUSTEP_APPS)/$(APP_FILE)
endif


$(GNUSTEP_APPS):
	$(MKINSTALLDIRS) $@

internal-app-uninstall::
	(cd $(GNUSTEP_APPS); rm -rf $(APP_DIR_NAME))

## Local variables:
## mode: makefile
## End:
