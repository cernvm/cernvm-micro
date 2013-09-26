include $(TOP)/config.mk
include config.mk

CURL_BINARY = curl-$(CURL_STRONG_VERSION)/bin/curl
CURL_BUILD_PRODUCT = $(CURL_SOURCETREE)/src/curl
CURL_STRIPPED = $(CURL_BUILD_PRODUCT)-stripped
CURL_MAKEFILE = $(CURL_SOURCETREE)/Makefile
CURL_CONFIGURE = $(CURL_SOURCETREE)/configure

all: $(CURL_BINARY)

clean:
	rm -rf curl-*

$(CURL_BINARY): $(CURL_STRIPPED)
	mkdir -p curl-$(CURL_STRONG_VERSION)/bin
	cp $(CURL_STRIPPED) $(CURL_BINARY)

$(CURL_STRIPPED): $(CURL_BUILD_PRODUCT)
	cp $(CURL_BUILD_PRODUCT) $(CURL_STRIPPED)
	strip $(CURL_STRIPPED)

$(CURL_BUILD_PRODUCT): $(CURL_MAKEFILE)
	$(MAKE) -j4 -C $(CURL_SOURCETREE)

$(CURL_MAKEFILE): $(CURL_CONFIGURE)
	cd $(CURL_SOURCETREE) && ./configure \
	  --enable-warnings \
	  --disable-ares \
	  --disable-shared \
	  --enable-static \
	  --disable-ftp \
	  --disable-file \
	  --disable-ldap \
	  --disable-ldaps \
	  --disable-rtsp \
	  --enable-http \
	  --disable-proxy \
	  --disable-dict \
	  --disable-telnet \
	  --disable-tftp \
	  --disable-pop3 \
	  --disable-imap \
	  --disable-smtp \
	  --disable-gopher \
	  --disable-threaded-resolver \
	  --disable-manual \
	  --enable-ipv6 \
	  --disable-sspi \
	  --disable-crypto-auth \
	  --disable-cookies \
	  --enable-symbol-hiding \
	  --disable-tls-srp \
	  --disable-ntlm-wb \
	  --without-ssl \
	  --without-winssl \
	  --without-darwinssl \
	  --without-gnutls \
	  --without-polarssl \
	  --without-cyassl \
	  --without-axtls \
 	  --without-nss \
	  --without-ca-bundle \
	  --without-ca-path \
	  --without-libssh2 \
	  --without-libmetalink \
	  --without-libidn \
	  --without-winidn \
	  --without-librtmp \
	  --disable-verbose	

$(CURL_CONFIGURE): | $(CURL_TARBALL)
	tar -xvzf $(CURL_TARBALL)

$(CURL_TARBALL):
	curl $(CURL_SOURCE) > $(CURL_TARBALL) 2>/dev/null || rm -f $(CURL_TARBALL)
