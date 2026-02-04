{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchPypi,
  python312,
  makeWrapper,
  gettext,
  libxml2,
  pkg-config,
  libxslt,
  file,
  cairo,
  pango,
  gdk-pixbuf,
  glib,
  libffi,
  libjpeg,
  zlib,
  freetype,
  lcms2,
  libtiff,
  libwebp,
  taigaContribOidcAuth ? null,
}:

let
  version = "6.9.0";

  python = python312.override {
    self = python;
    packageOverrides = self: super: {
      django = self.buildPythonPackage rec {
        pname = "Django";
        version = "3.2.25";
        pyproject = true;
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-fKOKeGVK7nI3hZTWPlFjbAS44oV09VBd/2MIlbVHJ3c=";
        };

        build-system = [ self.setuptools ];
                
        dependencies = [
          self.asgiref
          self.pytz
          self.sqlparse
        ];
        doCheck = false;
        patches = [];
      };

      moto = super.moto.overridePythonAttrs (old: {
        doCheck = false;
      });

      pytest-django = super.pytest-django.overridePythonAttrs (old: {
        doCheck = false;
      });

      debugpy = super.debugpy.overridePythonAttrs (old: {
        doCheck = false;
      });

      djangorestframework = self.buildPythonPackage rec {
        pname = "djangorestframework";
        version = "3.14.0";
        pyproject = true;
        
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-V5ozPmJWsJSJy+CgZ+ZqvlXGWV2JJr5rmUI3hjNDUMg=";
        };
        
        build-system = [ self.setuptools ];
        
        dependencies = [
          self.django
          self.pytz
        ];
        
        doCheck = false;
      };

      django-filter = self.buildPythonPackage rec {
        pname = "django-filter";
        version = "23.5";
        pyproject = true;
        
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-Z1g6pDuR/oxJ90qDLZX02EQr5ij9TG1l6fgR9RU6Tlw=";
        };
        
        build-system = [ self.setuptools self.flit-core ];
        
        dependencies = [
          self.django
        ];
        
        doCheck = false;
      };

      django-cors-headers = self.buildPythonPackage rec {
        pname = "django-cors-headers";
        version = "3.14.0";
        pyproject = true;
        
        src = fetchPypi {
          pname = "django_cors_headers";
          inherit version;
          hash = "sha256-X71YpvtBGdl1dUsrwJDzXsFgqDc/J2YSxnWwDooThzk=";
        };
        
        build-system = [ self.setuptools ];
        
        dependencies = [ self.django ];
        
        doCheck = false;
      };

      django-pglocks = self.buildPythonPackage rec {
        pname = "django-pglocks";
        version = "1.0.4";
        pyproject = true;
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-PEfGb7+9Jo70YmlnOgUWoDlTmwlyuO0uyc/uRMS2VSM=";
        };
        build-system = [ python.pkgs.setuptools ];
        propagatedBuildInputs = [ self.six self.django ];
        doCheck = false;
      };

      djmail = self.buildPythonPackage rec {
        pname = "djmail";
        version = "2.0.0";
        pyproject = true;
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-zzznYmMF0hiovytqIZJm74BhrO7vwccKVBcPQQVGUgI=";
        };
        build-system = [ python.pkgs.setuptools ];
        propagatedBuildInputs = [ self.django self.celery ];
        doCheck = false;
      };

      django-sr = self.buildPythonPackage rec {
        pname = "django-sr";
        version = "0.0.4";
        pyproject = true;
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-NYa4Uq6K8bSyeWWQU0sLhntSP0eld5ssy2zgEO/FfjQ=";
        };
        build-system = [ python.pkgs.setuptools ];
        propagatedBuildInputs = [ self.django ];
        doCheck = false;
      };

      easy-thumbnails = self.buildPythonPackage rec {
        pname = "easy-thumbnails";
        version = "2.8.5";
        pyproject = true;
        src = fetchFromGitHub {
          owner = "SmileyChris";
          repo = "easy-thumbnails";
          rev = version;
          hash = "sha256-mHKNh/OAtIebiP+JYePXe3M7HKwZ1Hc97cDoPiTn+HU=";
        };
        build-system = [ python.pkgs.setuptools ];
        propagatedBuildInputs = [ self.django self.pillow ];
        doCheck = false;
      };

      django-ipware = self.buildPythonPackage rec {
        pname = "django-ipware";
        version = "7.0.1";
        pyproject = true;
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-2exD0r983yFv7Y1JSghN61dhpUhgpTsudDRqTzhM/0c=";
        };
        build-system = [ python.pkgs.setuptools ];
        propagatedBuildInputs = [ self.python-ipware self.django ];
        doCheck = false;
      };

      #rudder-sdk-python = self.buildPythonPackage rec {
      #  pname = "rudder-sdk-python";
      #  version = "2.0.2";
      #  pyproject = true;
      #  src = fetchPypi {
      #    inherit pname version;
      #    hash = "sha256-RWm74Bg+qRvKfyNnH0Er2gNmS1W3ItMUVGOdZAmkIeo=";
      #  };
      #  build-system = [ python.pkgs.setuptools ];
      #  propagatedBuildInputs = [ self.pip self.deprecation self.monotonic self.python-dotenv self.requests self.backoff self.python-dateutil ];
      #  doCheck = false;
      #};

      premailer = self.buildPythonPackage rec {
        pname = "premailer";
        version = "3.10.0";
        pyproject = true;
        
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-0YdahBH13JK1Pvnxk9tsD4edw3jWGOCtKScj44i/5MI=";
        };
        
        build-system = [ self.setuptools ];
        
        dependencies = [
          self.lxml
          self.cssselect
          self.cssutils
          self.cachetools
          self.requests
        ];
        
        doCheck = false;
      };

      taiga-contrib-protected = self.buildPythonPackage rec {
        pname = "taiga-contrib-protected";
        version = "stable";
        pyproject = true;
        src = fetchFromGitHub {
          owner = "taigaio";
          repo = "taiga-contrib-protected";
          rev = version;
          hash = "sha256-C4t+7TnNaRIqArY+STlnm453klkRoVaEiqOCRoKb+Bc=";
        };

        nativeBuildInputs = [ 
          python.pkgs.versiontools 
          python.pkgs.setuptools
        ];
        
        preBuild = ''
          substituteInPlace setup.py \
            --replace "setup_requires=['versiontools >= 1.9']," "" \
            --replace "setup_requires=['versiontools>=1.9']," "" \
            --replace "setup_requires = ['versiontools >= 1.9']," "" \
            --replace "setup_requires = ['versiontools>=1.9']," ""
        '';
        propagatedBuildInputs = [ self.django ];
        doCheck = false;
      };

      bleach_4 = self.buildPythonPackage rec {
        pname = "bleach";
        version = "4.1.0";
        pyproject = true;
        
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-CQDYs366YagC7kCsAGH4wrXe4pwZJ90dIz4HXr9acdo=";
        };
        
        build-system = [ self.setuptools ];
        
        dependencies = [
          self.six
          self.webencodings
          self.html5lib
        ];
        
        doCheck = false;
      };

      django-picklefield = self.buildPythonPackage rec {
        pname = "django-picklefield";
        version = "3.2";
        pyproject = true;
        
        src = fetchPypi {
          pname = "django-picklefield";
          inherit version;
          hash = "sha256-qkY/XXnUl9vnifFLRRgPAKUdDWcAZ9BynzUqOUHN+k0=";
        };
        
        build-system = [ self.setuptools ];
        
        dependencies = [
          self.django
        ];
        
        doCheck = false;
      };
    };
  };

  pythonEnv = python.withPackages (ps: with ps; [
    django
    djangorestframework
    django-filter

    psycopg2

    celery
    amqp
    kombu

    gunicorn

    pillow
    cairosvg
    psd-tools
    scikit-image
    imageio

    bleach_4
    markdown
    pygments
    pymdown-extensions

    python-dateutil
    requests
    unidecode
    webcolors
    premailer
    python-magic
    cryptography
    pyjwt
    oauthlib

    django-cors-headers
    django-pglocks
    six
    djmail
    django-sr
    easy-thumbnails
    django-ipware
    python-ipware

    taiga-contrib-protected

    #rudder-sdk-python
    #sentry-sdk
    python-dotenv
    monotonic
    deprecation
    netaddr
    serpy
    django-jinja
    raven
    django-sites
    diff-match-patch
    django-picklefield
    mozilla-django-oidc
  ] ++ lib.optional (taigaContribOidcAuth != null) taigaContribOidcAuth);

in
stdenvNoCC.mkDerivation rec {
  pname = "taiga-back";
  inherit version;

  src = fetchFromGitHub {
    owner = "taigaio";
    repo = "taiga-back";
    rev = "stable";
    hash = "sha256-1iU+Gf2t7mhajKH8kA7aBFS6DWWBbsVX+/MUZR73oc4=";
  };

  nativeBuildInputs = [ makeWrapper gettext ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/taiga-back
    cp -r . $out/share/taiga-back/

    cd $out/share/taiga-back
    ${pythonEnv}/bin/python manage.py compilemessages 2>/dev/null || true

    mkdir -p $out/bin

    makeWrapper ${pythonEnv}/bin/python $out/bin/taiga-manage \
      --add-flags "$out/share/taiga-back/manage.py" \
      --set PYTHONPATH "$out/share/taiga-back" \
      --prefix PATH : "${lib.makeBinPath [ gettext ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ file cairo pango gdk-pixbuf glib libffi ]}"

    makeWrapper ${pythonEnv}/bin/gunicorn $out/bin/taiga-gunicorn \
      --chdir "$out/share/taiga-back" \
      --set PYTHONPATH "$out/share/taiga-back" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ file cairo pango gdk-pixbuf glib libffi ]}"

    makeWrapper ${pythonEnv}/bin/celery $out/bin/taiga-celery \
      --set PYTHONPATH "$out/share/taiga-back" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ file cairo pango gdk-pixbuf glib libffi ]}"

    runHook postInstall
  '';

  passthru = {
    inherit python pythonEnv;
  };

  meta = with lib; {
    description = "Taiga backend - REST API for agile project management";
    homepage = "https://github.com/taigaio/taiga-back";
    license = licenses.mpl20;
    platforms = platforms.linux;
  };
}
