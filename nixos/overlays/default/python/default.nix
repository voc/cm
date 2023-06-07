self: super: {
  diffsync = self.callPackage ./diffsync { };
  python-yate = self.callPackage ./python-yate { };
  mitel-ommclient2 = self.callPackage ./mitel-ommclient2 { };
  django-admin-autocomplete-filter = self.callPackage ./django-admin-autocomplete-filter { };
  django-bootstrap5 = self.callPackage ./django-bootstrap5 { };
  django-verify-email = self.callPackage ./django-verify-email { };
}
