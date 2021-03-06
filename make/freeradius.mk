###########################################################
#
# freeradius
#
###########################################################

# You must replace "freeradius" and "FREERADIUS" with the lower case name and
# upper case name of your new package.  Some places below will say
# "Do not change this" - that does not include this global change,
# which must always be done to ensure we have unique names.

#
# FREERADIUS_VERSION, FREERADIUS_SITE and FREERADIUS_SOURCE define
# the upstream location of the source code for the package.
# FREERADIUS_DIR is the directory which is created when the source
# archive is unpacked.
# FREERADIUS_UNZIP is the command used to unzip the source.
# It is usually "zcat" (for .gz) or "bzcat" (for .bz2)
#
# You should change all these variables to suit your package.
#
FREERADIUS_SITE=ftp://ftp.freeradius.org/pub/radius
FREERADIUS_SITE2=$(FREERADIUS_SITE)/old
FREERADIUS_VERSION=3.0.10
FREERADIUS_DIR=freeradius-server-$(FREERADIUS_VERSION)
FREERADIUS_SOURCE=$(FREERADIUS_DIR).tar.bz2
FREERADIUS_UNZIP=bzcat
FREERADIUS_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
FREERADIUS_DESCRIPTION=An open source RADIUS server.
FREERADIUS_SECTION=net
FREERADIUS_PRIORITY=optional
FREERADIUS_DEPENDS=libtool, openssl, psmisc, talloc, libpcap, busybox-base
FREERADIUS_SUGGESTS=freeradius-doc
FREERADIUS_CONFLICTS=

#
# FREERADIUS_IPK_VERSION should be incremented when the ipk changes.
#
FREERADIUS_IPK_VERSION=4

#
# FREERADIUS_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
FREERADIUS_PATCHES=\
$(FREERADIUS_SOURCE_DIR)/configure.ac.patch \
$(FREERADIUS_SOURCE_DIR)/headers.patch \
$(FREERADIUS_SOURCE_DIR)/acinclude.m4.patch \
$(FREERADIUS_SOURCE_DIR)/hostname.patch \

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
FREERADIUS_CPPFLAGS=
FREERADIUS_LDFLAGS=-lm

ifneq (, $(filter dns323, $(OPTWARE_TARGET)))
FREERADIUS_CONFIG_ARGS = --without-rlm-sql-mysql
else
FREERADIUS_CONFIG_ARGS = \
	--with-rlm-sql-mysql-include-dir=$(STAGING_INCLUDE_DIR)/mysql \
	--with-rlm-sql-mysql-lib-dir=$(STAGING_LIB_DIR)/mysql
FREERADIUS_CPPFLAGS += -I$(STAGING_INCLUDE_DIR)/mysql
FREERADIUS_LDFLAGS += -L$(STAGING_LIB_DIR)/mysql -Wl,-rpath,$(TARGET_PREFIX)/lib/mysql -Wl,-rpath-link,$(STAGING_LIB_DIR)/mysql
endif
#
# FREERADIUS_BUILD_DIR is the directory in which the build is done.
# FREERADIUS_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# FREERADIUS_IPK_DIR is the directory in which the ipk is built.
# FREERADIUS_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
FREERADIUS_BUILD_DIR=$(BUILD_DIR)/freeradius
FREERADIUS_SOURCE_DIR=$(SOURCE_DIR)/freeradius
FREERADIUS_IPK_DIR=$(BUILD_DIR)/freeradius-$(FREERADIUS_VERSION)-ipk
FREERADIUS_DOC_IPK_DIR=$(BUILD_DIR)/freeradius-doc-$(FREERADIUS_VERSION)-ipk
FREERADIUS_IPK=$(BUILD_DIR)/freeradius_$(FREERADIUS_VERSION)-$(FREERADIUS_IPK_VERSION)_$(TARGET_ARCH).ipk
FREERADIUS_DOC_IPK=$(BUILD_DIR)/freeradius-doc_$(FREERADIUS_VERSION)-$(FREERADIUS_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: freeradius-source freeradius-unpack freeradius freeradius-stage freeradius-ipk freeradius-clean freeradius-dirclean freeradius-check

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(FREERADIUS_SOURCE):
	$(WGET) -P $(@D) $(FREERADIUS_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(FREERADIUS_SITE2)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

#
# The source code depends on it existing within the download directory.
# This target will be called by the top level Makefile to download the
# source code's archive (.tar.gz, .bz2, etc.)
#
freeradius-source: $(DL_DIR)/$(FREERADIUS_SOURCE) $(FREERADIUS_PATCHES)

#
# This target unpacks the source code in the build directory.
# If the source archive is not .tar.gz or .tar.bz2, then you will need
# to change the commands here.  Patches to the source code are also
# applied in this target as required.
#
# This target also configures the build within the build directory.
# Flags such as LDFLAGS and CPPFLAGS should be passed into configure
# and NOT $(MAKE) below.  Passing it to configure causes configure to
# correctly BUILD the Makefile with the right paths, where passing it
# to Make causes it to override the default search paths of the compiler.
#
# If the compilation of the package requires other packages to be staged
# first, then do that first (e.g. "$(MAKE) <bar>-stage <baz>-stage").
#
$(FREERADIUS_BUILD_DIR)/.configured: $(DL_DIR)/$(FREERADIUS_SOURCE) $(FREERADIUS_PATCHES) make/freeradius.mk
	$(MAKE) openssl-stage libtool-stage talloc-stage postgresql-stage unixodbc-stage libpcap-stage
ifeq (, $(filter --without-rlm-sql-mysql, $(FREERADIUS_CONFIG_ARGS)))
	$(MAKE) mysql-stage
endif
	rm -rf $(BUILD_DIR)/$(FREERADIUS_DIR) $(@D)
	$(FREERADIUS_UNZIP) $(DL_DIR)/$(FREERADIUS_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	if test -n "$(FREERADIUS_PATCHES)"; \
		then cat $(FREERADIUS_PATCHES) | $(PATCH) -d $(BUILD_DIR)/$(FREERADIUS_DIR) -p1; \
	fi
	mv $(BUILD_DIR)/$(FREERADIUS_DIR) $(@D)
	sed -i.orig -e '/rlm_perl\|rlm_pam/d' $(@D)/src/modules/stable
	sed -i -e '/^smart_include_dir=/s|=.*|="$(TARGET_INCDIR) $(STAGING_INCLUDE_DIR)"|' $(@D)/acinclude.m4
	$(AUTORECONF1.14) -vif $(@D)
	rm -rf $(@D)/src/modules/rlm_krb5
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="-I$(STAGING_INCLUDE_DIR)/libtalloc $(STAGING_CPPFLAGS) $(FREERADIUS_CPPFLAGS)" \
		CFLAGS="-I$(STAGING_INCLUDE_DIR)/libtalloc $(STAGING_CPPFLAGS) $(FREERADIUS_CPPFLAGS)" \
		LDFLAGS="-L$(STAGING_LIB_DIR)/talloc -Wl,-rpath,$(TARGET_PREFIX)/lib/talloc -Wl,-rpath-link,$(STAGING_LIB_DIR)/talloc $(STAGING_LDFLAGS) $(FREERADIUS_LDFLAGS)" \
		MYSQL_CONFIG=yes \
		PATH="$(STAGING_PREFIX)/bin:$$PATH" \
		PKG_CONFIG_PATH="$(STAGING_LIB_DIR)/pkgconfig" \
		PKG_CONFIG_LIBDIR="$(STAGING_LIB_DIR)/pkgconfig" \
		ax_cv_cc_builtin_choose_expr="yes" \
		ax_cv_cc_builtin_types_compatible_p="yes" \
		ax_cv_cc_builtin_bswap64="yes" \
		ax_cv_cc_bounded_attribute="yes" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=$(TARGET_PREFIX) \
		--libdir=$(TARGET_PREFIX)/lib \
		--with-raddbdir=$(TARGET_PREFIX)/etc/raddb \
		--with-openssl-includes=$(STAGING_INCLUDE_DIR) \
		--with-openssl-libraries=$(STAGING_LIB_DIR) \
		$(FREERADIUS_CONFIG_ARGS) \
		--with-rlm-sql-postgresql-include-dir=$(STAGING_INCLUDE_DIR) \
		--with-rlm-sql-postgresql-lib-dir=$(STAGING_LIB_DIR) \
		--with-rlm-sql-unixodbc-include-dir=$(STAGING_INCLUDE_DIR) \
		--with-rlm-sql-unixodbc-lib-dir=$(STAGING_LIB_DIR) \
	)
	sed -i -e '/^SRC_CFLAGS\t:=/s/=.*/=/' -e '/^TGT_LDLIBS\t:=/s/=.*/= -lodbc/' $(@D)/src/modules/rlm_sql/drivers/rlm_sql_unixodbc/all.mk
	sed -i -e '/^SRC_CFLAGS\t:=/s/=.*/=/' -e '/^TGT_LDLIBS\t:=/s/=.*/= -lpq/' $(@D)/src/modules/rlm_sql/drivers/rlm_sql_postgresql/all.mk
	touch $@

freeradius-unpack: $(FREERADIUS_BUILD_DIR)/.configured

#
# This builds the actual binary.  You should change the target to refer
# directly to the main binary which is built.
#
$(FREERADIUS_BUILD_DIR)/.built: $(FREERADIUS_BUILD_DIR)/.configured
	rm -f $@
	$(HOSTCC) $(@D)/scripts/jlibtool.c -o $(@D)/jlibtool
	$(MAKE) -C $(@D) headers
	$(MAKE) -C $(@D) JLIBTOOL=$(@D)/jlibtool
	$(MAKE) install -C $(@D) JLIBTOOL=$(@D)/jlibtool -j 1 \
		R=$(@D)/install \
		STRIPPROG=$(TARGET_STRIP) \
		;
	touch $@

#
# You should change the dependency to refer directly to the main binary
# which is built.
#
freeradius: $(FREERADIUS_BUILD_DIR)/.built
#
# If you are building a library, then you need to stage it too.
#
$(FREERADIUS_BUILD_DIR)/.staged: $(FREERADIUS_BUILD_DIR)/.built
	rm -f $@
	$(INSTALL) -d $(STAGING_INCLUDE_DIR)
	$(INSTALL) -m 644 $(@D)/freeradius.h $(STAGING_INCLUDE_DIR)
	$(INSTALL) -d $(STAGING_LIB_DIR)/freeradius
	$(INSTALL) -m 644 $(@D)/libfreeradius.a $(STAGING_LIB_DIR)/freeradius
	$(INSTALL) -m 644 $(@D)/libfreeradius.so.$(FREERADIUS_VERSION) $(STAGING_LIB_DIR)/freeradius
	cd $(STAGING_LIB_DIR) && ln -fs libfreeradius.so.$(FREERADIUS_VERSION) libfreeradius.so.1
	cd $(STAGING_LIB_DIR) && ln -fs libfreeradius.so.$(FREERADIUS_VERSION) libfreeradius.so
	cp -rf $(@D)/install/lib/* $(STAGING_LIB_DIR)/freeradius/
	touch $@

freeradius-stage: $(FREERADIUS_BUILD_DIR)/.staged

$(FREERADIUS_IPK_DIR)/CONTROL/control:
	@$(INSTALL) -d $(@D)
	@rm -f $@
	@echo "Package: freeradius" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(FREERADIUS_PRIORITY)" >>$@
	@echo "Section: $(FREERADIUS_SECTION)" >>$@
	@echo "Version: $(FREERADIUS_VERSION)-$(FREERADIUS_IPK_VERSION)" >>$@
	@echo "Maintainer: $(FREERADIUS_MAINTAINER)" >>$@
	@echo "Source: $(FREERADIUS_SITE)/$(FREERADIUS_SOURCE)" >>$@
	@echo "Description: $(FREERADIUS_DESCRIPTION)" >>$@
	@echo "Depends: $(FREERADIUS_DEPENDS)" >>$@
	@echo "Suggests: $(FREERADIUS_SUGGESTS)" >>$@
	@echo "Conflicts: $(FREERADIUS_CONFLICTS)" >>$@

$(FREERADIUS_DOC_IPK_DIR)/CONTROL/control:
	@$(INSTALL) -d $(@D)
	@rm -f $@
	@echo "Package: freeradius-doc" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(FREERADIUS_PRIORITY)" >>$@
	@echo "Section: $(FREERADIUS_SECTION)" >>$@
	@echo "Version: $(FREERADIUS_VERSION)-$(FREERADIUS_IPK_VERSION)" >>$@
	@echo "Maintainer: $(FREERADIUS_MAINTAINER)" >>$@
	@echo "Source: $(FREERADIUS_SITE)/$(FREERADIUS_SOURCE)" >>$@
	@echo "Description: $(FREERADIUS_DESCRIPTION)" >>$@

#
# This builds the IPK file.
#
# Binaries should be installed into $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/sbin or $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/{lib,include}
# Configuration files should be installed in $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/etc/freeradius/...
# Documentation files should be installed in $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/doc/freeradius/...
# Daemon startup scripts should be installed in $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/etc/init.d/S??freeradius
#
# You may need to patch your application to make it use these locations.
#
$(FREERADIUS_IPK): $(FREERADIUS_BUILD_DIR)/.built
	rm -rf $(FREERADIUS_IPK_DIR) $(BUILD_DIR)/freeradius_*_$(TARGET_ARCH).ipk
	$(INSTALL) -d $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)
	cp -rf $(FREERADIUS_BUILD_DIR)/install/* $(FREERADIUS_IPK_DIR)/
	rm -rf $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/share/doc
	$(INSTALL) -d $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/doc/.radius
	rm -rf $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/lib/*.a
	rm -rf $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/man/*
	rm -rf $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/share/man/*
	mv $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/etc/* $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/doc/.radius/
	$(INSTALL) -d $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/etc/init.d
	-$(STRIP_COMMAND) $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/{{bin,sbin}/*,lib/*.so}
	$(INSTALL) -m 755 $(FREERADIUS_SOURCE_DIR)/rc.freeradius $(FREERADIUS_IPK_DIR)$(TARGET_PREFIX)/etc/init.d/S55freeradius
	$(MAKE) $(FREERADIUS_IPK_DIR)/CONTROL/control
	$(INSTALL) -m 644 $(FREERADIUS_SOURCE_DIR)/postinst $(FREERADIUS_IPK_DIR)/CONTROL/postinst
	$(INSTALL) -m 644 $(FREERADIUS_SOURCE_DIR)/prerm $(FREERADIUS_IPK_DIR)/CONTROL/prerm
	cd $(BUILD_DIR); $(IPKG_BUILD) $(FREERADIUS_IPK_DIR)

$(FREERADIUS_DOC_IPK): $(FREERADIUS_BUILD_DIR)/.built
	rm -rf $(FREERADIUS_DOC_IPK_DIR) $(BUILD_DIR)/freeradius-doc_*_$(TARGET_ARCH).ipk
	$(INSTALL) -d $(FREERADIUS_DOC_IPK_DIR)$(TARGET_PREFIX)/doc
	$(INSTALL) -d $(FREERADIUS_DOC_IPK_DIR)$(TARGET_PREFIX)/man
	cp -rf $(FREERADIUS_BUILD_DIR)/install$(TARGET_PREFIX)/share/man/* $(FREERADIUS_DOC_IPK_DIR)$(TARGET_PREFIX)/man/
	cp -rf $(FREERADIUS_BUILD_DIR)/install$(TARGET_PREFIX)/share/doc/* $(FREERADIUS_DOC_IPK_DIR)$(TARGET_PREFIX)/doc/
	$(INSTALL) -d $(FREERADIUS_DOC_IPK_DIR)/CONTROL
	$(MAKE) $(FREERADIUS_DOC_IPK_DIR)/CONTROL/control
	cd $(BUILD_DIR); $(IPKG_BUILD) $(FREERADIUS_DOC_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
freeradius-ipk: $(FREERADIUS_IPK) $(FREERADIUS_DOC_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
freeradius-clean:
	-$(MAKE) -C $(FREERADIUS_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
freeradius-dirclean:
	rm -rf $(BUILD_DIR)/$(FREERADIUS_DIR) $(FREERADIUS_BUILD_DIR) $(FREERADIUS_IPK_DIR) $(FREERADIUS_IPK)
	rm -rf $(FREERADIUS_DOC_IPK_DIR) $(FREERADIUS_DOC_IPK)

#
# Some sanity check for the package.
#
freeradius-check: $(FREERADIUS_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $(FREERADIUS_IPK)
